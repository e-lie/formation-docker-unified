import flask_unittest
from src.monster_icon import app


class TestMainPage(flask_unittest.AppTestCase):

    def create_app(self):
        return app

    def test_mainpage(self, app):
        with app.test_client() as client:
            result = client.get('/')
            # vérifier qu'on ne trouve pas `cannot connect` dans la page => Redis est joignable
            # "l'integration" des différentes parties de l'application fonctionne 
            self.assertTrue(b'cannot connect to Redis' not in result.data)
            