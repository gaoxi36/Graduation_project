from Push_Play import PUSH_PLAY

def Printing():
    for i in p.Result:
        Result.append(i)

if __name__ == '__main__':

    Result = []


    p = PUSH_PLAY('10.226.133.19', 'test-push.push.jcloud.com', 'live', 'stream0',
                  '10.226.133.19', 'test-push.play.jcloud.com', 'live', 'stream0', 1)
    Printing()

    p = PUSH_PLAY('', '', '', '',
                  '10.226.133.19', 'test-fetch.play.jcloud.com', 'live', 'stream0', 2)
    Printing()

    p = PUSH_PLAY('10.226.133.19', 'test-mix.push.jcloud.com', 'live', 'stream0',
                  '10.226.133.19', 'test-mix.play.jcloud.com', 'live', 'stream0', 3)
    Printing()

    p = PUSH_PLAY('10.226.133.19', 'test-internal-push.push.jcloud.com', 'live', 'stream0',
                  '10.226.133.19', 'test-internal-push.play.jcloud.com', 'live', 'stream0',10)
    Printing()

    p = PUSH_PLAY('', '', '', '',
                  '10.226.133.19', 'play.6roomtest.com', 'live', 'stream0', 11)
    Printing()

    p = PUSH_PLAY('10.226.133.19', 'test-internal-mix.push.jcloud.com', 'live', 'stream0',
                  '10.226.133.19', 'test-internal-mix.play.jcloud.com', 'live', 'stream0', 12)
    Printing()

    for i in Result:
        print(i)