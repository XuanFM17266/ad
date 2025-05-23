DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '111111',
    'database': 'advertisements',
    'port': 3306
}

# 连接模块部分
import mysql.connector
from mysql.connector import Error  # 确保正确导入 Error 类


def get_connection():
    """获取数据库连接，并处理异常"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        print("数据库连接成功")
        return conn
    except Error as e:  # 注意缩进和冒号
        print(f"数据库连接失败: {e}")
        return None


def execute_query(query, params=None, is_write=False):
    """执行查询并返回结果（支持读写操作）"""
    conn = get_connection()
    if not conn:
        return None

    cursor = None
    try:
        cursor = conn.cursor()
        cursor.execute(query, params or ())

        if is_write:
            conn.commit()
            print("操作已提交")
            result = cursor.rowcount
        else:
            result = cursor.fetchall()

        return result
    except Error as e:  # 注意缩进和冒号
        print(f"操作失败: {e}")
        if is_write:
            conn.rollback()
        return None
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


if __name__ == "__main__":
    # 测试查询
    select_result = execute_query("SELECT * FROM `ads`")
    print("查询结果:", select_result)
