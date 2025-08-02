from flask import Flask, request, send_from_directory, render_template_string, abort
import os

app = Flask(__name__)
UPLOAD_FOLDER = os.path.abspath('uploads')  # Use absolute path
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return 'No file part', 400
    files = request.files.getlist('file')  # Handle multiple files
    if not files:
        return 'No selected files', 400
    for file in files:
        if file.filename == '':
            return 'No selected file', 400
        if file:
            filename = file.filename
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
    return 'Files uploaded successfully', 200

@app.route('/download/<filename>')
def download_file(filename):
    try:
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename, as_attachment=True)
    except FileNotFoundError:
        abort(404)  # Proper 404 handling

@app.route('/download')
def download_page():
    files = os.listdir(app.config['UPLOAD_FOLDER'])
    html = """
    <html>
        <head><title>Download Files</title></head>
        <body>
            <h1>Files Available for Download</h1>
            <ul>
                {% for file in files %}
                    <li>
                        <a href="/download/{{ file }}" download>{{ file }}</a>
                        {% if file.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')) %}
                            <br><img src="/download/{{ file }}" alt="{{ file }}" style="max-width: 200px; max-height: 200px;">
                        {% endif %}
                    </li>
                {% endfor %}
            </ul>
        </body>
    </html>
    """
    return render_template_string(html, files=files)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)