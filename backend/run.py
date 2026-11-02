import os
import sys

# Ensure backend directory is in sys.path
backend_dir = os.path.dirname(os.path.abspath(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import uvicorn
from app.core.config import settings

if __name__ == "__main__":
    port = int(os.getenv("PORT", str(settings.PORT)))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"Starting {settings.PROJECT_NAME} on http://{host}:{port}")
    print(f"Interactive API Docs available at http://127.0.0.1:{port}/docs")
    uvicorn.run("app.main:app", host=host, port=port, reload=False)
