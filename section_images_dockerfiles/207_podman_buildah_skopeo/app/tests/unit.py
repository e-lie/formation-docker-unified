import flask_unittest
from src.monster_icon import app


class TestMainPage(flask_unittest.AppTestCase):

    def create_app(self):
        return app

    def test_mainpage_html(self, app):
        with app.test_client() as client:
            result = client.get('/')
            # vérifier que la fonction mainpage renvoie bien du html
            self.assertTrue(b'<html>' in result.data)
    
    def test_mainpage_redis_unreachable(self, app):
        with app.test_client() as client:
            result = client.get('/')
        # vérifier que la partie qui vérifie la correction redis fonctionne
        # pas redis en unit test <=> cannot connect
            self.assertTrue(b'cannot connect to Redis' in result.data)
            