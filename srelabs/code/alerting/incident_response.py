from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['POST'])
def webhook():
    data = request.json
    print("🚨 Incident detected! Alert received:", data)
    # Example: automatic action could be restarting a service
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
