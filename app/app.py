from flask import (
    Flask,
    request,
    jsonify
)
from dotenv import dotenv_values, load_dotenv
import hashlib
import hmac
import subprocess

def register_app():
    app = Flask(__name__, static_folder=None)
    load_dotenv()
    config = dotenv_values()
    app.config.from_mapping(config)
    return app

def validate_signature(payload_body, secret_token, signature_header):
    if not signature_header:
        raise RuntimeError("Error validating signature - signature is empty")
    hash_object = hmac.new(secret_token.encode("utf-8"), msg=payload_body, digestmod=hashlib.sha256)
    expected_signature = "sha256=" + hash_object.hexdigest()
    if not hmac.compare_digest(expected_signature, signature_header):
        raise ValueError("Error validating signature - signatures do not match")

app = register_app()

@app.route("/", methods=["POST"])
def git_pull():
    try:
        validate_signature(request.data, app.config["GITHOOK_SECRET"] ,request.headers.get("X-Hub-Signature-256", ""))
    except (RuntimeError, ValueError) as e:
        print(e)
        return jsonify({
            "status": "ERROR",
            "error": str(e)
        }), 403
    try:
        pull_result = subprocess.run(
            ["git", "pull"],
            cwd = app.config["REPO_DIR"],
            capture_output = True,
            text = True,
            check = True
        )
        print("Pull results:\n", pull_result.stdout)
    except subprocess.CalledProcessError:
        return jsonify({
            "status": "ERROR",
            "error": "Failed to pull git repository"
        }), 500
    except FileNotFoundError:
        return jsonify({
            "status": "ERROR",
            "error": "Repository folder not found"
        })
    return jsonify({
        "status": "OK",
        "error": None
    })
    

def main():
    app.run(debug=True, port=5500, host="0.0.0.0")

if __name__ == "__main__":
    main()