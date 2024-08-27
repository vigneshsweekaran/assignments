from flask import Flask, request, jsonify
import uuid
import mysql.connector
import logging

app = Flask(__name__)

# Setup MySQL connection
db = mysql.connector.connect(
    host="mysql_host",  # Should be configured in your Docker setup
    user="root",
    password="password",
    database="messages_db"
)

# Logger setup
logging.basicConfig(level=logging.INFO)

@app.route('/create', methods=['POST'])
def create_message():
    data = request.json
    account_id = data.get('account_id')
    sender_number = data.get('sender_number')
    receiver_number = data.get('receiver_number')
    
    if not account_id or not sender_number or not receiver_number:
        return jsonify({"error": "Missing data"}), 400

    message_id = str(uuid.uuid4())
    cursor = db.cursor()

    try:
        cursor.execute("INSERT INTO messages (account_id, message_id, sender_number, receiver_number) VALUES (%s, %s, %s, %s)",
                       (account_id, message_id, sender_number, receiver_number))
        db.commit()
        logging.info(f"Message created with ID {message_id}")
        return jsonify({"message_id": message_id}), 201
    except Exception as e:
        logging.error(f"Error creating message: {e}")
        return jsonify({"error": "Failed to create message"}), 500


@app.route('/get/messages/<account_id>', methods=['GET'])
def get_messages(account_id):
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM messages WHERE account_id = %s", (account_id,))
    messages = cursor.fetchall()

    if not messages:
        return jsonify({"error": "No messages found"}), 404

    return jsonify(messages), 200


@app.route('/search', methods=['GET'])
def search_messages():
    message_id = request.args.get('message_id')
    sender_number = request.args.get('sender_number')
    receiver_number = request.args.get('receiver_number')

    query = "SELECT * FROM messages WHERE 1=1"
    params = []

    if message_id:
        query += " AND message_id IN (%s)" % ",".join(["%s"] * len(message_id.split(",")))
        params += message_id.split(",")
    
    if sender_number:
        query += " AND sender_number IN (%s)" % ",".join(["%s"] * len(sender_number.split(",")))
        params += sender_number.split(",")
    
    if receiver_number:
        query += " AND receiver_number IN (%s)" % ",".join(["%s"] * len(receiver_number.split(",")))
        params += receiver_number.split(",")

    cursor = db.cursor(dictionary=True)
    cursor.execute(query, params)
    messages = cursor.fetchall()

    return jsonify(messages), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
