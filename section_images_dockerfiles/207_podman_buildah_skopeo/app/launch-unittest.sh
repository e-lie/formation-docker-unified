

python -m virtualenv venv

source venv/bin/activate

pip install -r requirements.dev.txt

python -m unittest tests/unit.py