from flask import Flask  
import socket, datetime, random, string

app = Flask(__name__)  
start_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")  
container_id = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

@app.route('/')  
def hello():  
    return f"""  
    Hello from Flask!<br>  
    Hostname: {socket.gethostname()}<br>  
    Container start time: {start_time}<br>  
    Container ID: {container_id}  
    """

@app.route('/health')  
def health():  
    return "OK", 200

if __name__ == '__main__':  
    app.run(host='0.0.0.0', port=5000)
