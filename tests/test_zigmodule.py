import unittest

from pyzig import zigmodule


class TestZigModule(unittest.TestCase):
    def test_sumz(self):
        self.assertEqual(zigmodule.sumz(2, 2), 4)

    def test_multz(self):
        self.assertEqual(zigmodule.multz(4, 4), 16)

    def test_divz(self):
        self.assertEqual(zigmodule.divz(4, 2), 2)


if __name__ == "__main__":
    unittest.main()
