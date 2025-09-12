from flask import Flask
import socket, datetime, os

app = Flask(__name__)
start_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
restart_count = 0

if os.path.exists('/app/restart_count.txt'):
    with open('/app/restart_count.txt', 'r') as f:
        restart_count = int(f.read()) + 1
else:

    restart_count = 0

with open('/app/restart_count.txt', 'w') as f:
    f.write(str(restart_count))

@app.route('/')
def home():
    return f"""
    <h2>Hello from Flask!</h2>
    Hostname: {socket.gethostname()}<br>
    Container start time: {start_time}<br>
    Restart count: {restart_count}
    """

@app.route('/api/data')
def api_data():
    return {"message": "This is sample API data", "status": "OK"}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

