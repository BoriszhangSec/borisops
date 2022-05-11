#!/usr/bin/python
class Ant

    def __init__(self, x=0, y=0, color='black'):
        self.x = x
        self.y = y
        self.color = color

    def crwl(self, x, y):
        self.x = x
        self.y = y
        print('paxing...')

    def info(self):
        print('dangqianweizhi:(%d,%d)' % (self.x, self.y))

    def attack(self):
        print("yongcuiyao!")


class FlyAnt(Ant):
    def attack(self):
        print("yongweizhen!")

    def fly(self, x, y):
        print('feixing...')
        self.x = x
        self.y = y
        self.info()


flyant = FlyAnt(color='red')
flyant.craw(3, 5)
flyant.fly(10, 14)
flyant.attack()
