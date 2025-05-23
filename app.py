from flask import Flask, request, jsonify, render_template, session, redirect, url_for
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
import datetime
import stripe
import os

# 初始化 Flask 应用
app = Flask(__name__, static_folder='static', template_folder='templates')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///ad_platform.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'your-secret-key-here'
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = datetime.timedelta(hours=1)

# 初始化扩展
db = SQLAlchemy(app)
jwt = JWTManager(app)

# 配置 Stripe
stripe.api_key = "sk_test_51RRjVDQrqRWFg1iGjmwOujyTZUKMoLXvUlszB9yNeLbGA1A4PvrmmbPB5JD4IK0mkOUOrVyVWF8o5W2Q6hwKCsVF00p2xqcVL1"  # 替换为您的 Stripe 测试密钥


# 模型定义
class UserRole(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    role_id = db.Column(db.Integer, db.ForeignKey('user_role.id'), default=2)  # 默认是广告主
    balance = db.Column(db.Float, default=0.0)
    ads = db.relationship('Ad', backref='user', lazy=True)
    transactions = db.relationship('Transaction', backref='user', lazy=True)


class AdStatus(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)


class Ad(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)
    daily_budget = db.Column(db.Float, nullable=False)
    start_date = db.Column(db.DateTime, nullable=False)
    status_id = db.Column(db.Integer, db.ForeignKey('ad_status.id'), default=1)  # 默认待审核
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)


class Transaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    amount = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    status = db.Column(db.String(20), default="success")
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)


class Invoice(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    company_name = db.Column(db.String(100), nullable=False)
    tax_id = db.Column(db.String(50), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

@app.route('/api/user/balance', methods=['GET'])
@jwt_required()
def get_user_balance():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    return jsonify({"balance": user.balance}), 200
# API 路由
@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()

    # 检查邮箱是否已注册
    if User.query.filter_by(email=data['email']).first():
        return jsonify({"message": "Email already exists"}), 400

    # 创建新用户
    new_user = User(
        username=data['username'],
        email=data['email'],
        password_hash=generate_password_hash(data['password']),
        role_id=2  # 默认广告主
    )

    db.session.add(new_user)
    db.session.commit()

    return jsonify({"message": "User registered successfully"}), 201


@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()

    if not user or not check_password_hash(user.password_hash, data['password']):
        return jsonify({"message": "Invalid credentials"}), 401

    # 创建 JWT token
    access_token = create_access_token(identity=user.id)

    return jsonify({
        "access_token": access_token,
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "balance": user.balance,
            "role": user.role.name if user.role else "advertiser"
        }
    }), 200


@app.route('/api/ads', methods=['GET'])
@jwt_required()
def get_ads():
    current_user_id = get_jwt_identity()
    ads = Ad.query.filter_by(user_id=current_user_id).all()

    ads_list = []
    for ad in ads:
        ads_list.append({
            "id": ad.id,
            "title": ad.title,
            "content": ad.content,
            "daily_budget": ad.daily_budget,
            "start_date": ad.start_date.strftime('%Y-%m-%d'),
            "status": ad.status.name if ad.status else "pending",
            "created_at": ad.created_at.strftime('%Y-%m-%d %H:%M:%S')
        })

    return jsonify(ads_list), 200


@app.route('/api/ads', methods=['POST'])
@jwt_required()
def create_ad():
    data = request.get_json()
    current_user_id = get_jwt_identity()

    # 创建新广告
    new_ad = Ad(
        title=data['title'],
        content=data['content'],
        daily_budget=data['daily_budget'],
        start_date=datetime.datetime.strptime(data['start_date'], '%Y-%m-%d'),
        user_id=current_user_id
    )

    db.session.add(new_ad)
    db.session.commit()

    return jsonify({
        "message": "Ad created successfully",
        "ad_id": new_ad.id
    }), 201


@app.route('/api/payment/charge', methods=['POST'])
@jwt_required()
def process_payment():
    data = request.get_json()
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)

    try:
        # 创建 Stripe 支付意图
        intent = stripe.PaymentIntent.create(
            amount=int(data['amount'] * 100),  # 转换为分
            currency='cny',
            payment_method=data['payment_method'],
            confirm=True,
            return_url='http://your-domain.com/success'
        )

        # 支付成功，更新用户余额
        user.balance += data['amount']

        # 记录交易
        transaction = Transaction(
            amount=data['amount'],
            user_id=current_user_id
        )

        db.session.add(transaction)
        db.session.commit()

        return jsonify({
            "message": "Payment successful",
            "new_balance": user.balance,
            "transaction_id": transaction.id
        }), 200

    except stripe.error.CardError as e:
        return jsonify({"error": e.user_message}), 400
    except Exception as e:
        return jsonify({"error": "Payment failed"}), 500


@app.route('/api/transactions', methods=['GET'])
@jwt_required()
def get_transactions():
    current_user_id = get_jwt_identity()
    transactions = Transaction.query.filter_by(user_id=current_user_id).all()

    transactions_list = []
    for transaction in transactions:
        transactions_list.append({
            "id": transaction.id,
            "amount": transaction.amount,
            "created_at": transaction.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            "status": transaction.status
        })

    return jsonify(transactions_list), 200


@app.route('/api/invoices', methods=['POST'])
@jwt_required()
def create_invoice():
    data = request.get_json()
    current_user_id = get_jwt_identity()

    # 创建发票
    invoice = Invoice(
        company_name=data['company_name'],
        tax_id=data['tax_id'],
        amount=data['amount'],
        user_id=current_user_id
    )

    db.session.add(invoice)
    db.session.commit()

    return jsonify({
        "message": "Invoice created successfully",
        "invoice_id": invoice.id
    }), 201


# 前端路由
@app.route('/')
def index():
    return render_template('index.html')


if __name__ == '__main__':
    # 创建数据库表
    with app.app_context():
        db.create_all()

        # 初始化角色和状态
        if not UserRole.query.first():
            admin_role = UserRole(name='admin')
            advertiser_role = UserRole(name='advertiser')
            db.session.add(admin_role)
            db.session.add(advertiser_role)
            db.session.commit()

        if not AdStatus.query.first():
            pending_status = AdStatus(name='pending')
            approved_status = AdStatus(name='approved')
            rejected_status = AdStatus(name='rejected')
            paused_status = AdStatus(name='paused')
            running_status = AdStatus(name='running')
            db.session.add_all([pending_status, approved_status, rejected_status, paused_status, running_status])
            db.session.commit()

    app.run(debug=True)
