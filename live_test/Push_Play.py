#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 ob767, Inc. All Rights Reserved
#

from Ffmpeg import FFMPEG
from multiprocessing import Pool
import time

class PUSH_PLAY:

    def play_rtmp(self, *Server):
        f = FFMPEG()
        f.set_play_config(ip = Server[0], port = Server[1], app = Server[3], stream = Server[4])
        return f.ffplay_rtmp_play()

    def play_m3u8(self, *Server):
        f = FFMPEG()
        f.set_play_config(ip = Server[0], port = Server[2], app = Server[3], stream = Server[4])
        return f.ffplay_m3u8_play()

    def play_flv(self, *Server):
        f = FFMPEG()
        f.set_play_config(ip = Server[0], port = Server[2], app = Server[3], stream = Server[4])
        return f.ffplay_flv_play()

    def test_play(self, Server):
        p = Pool(3)
        p1 = p.apply_async(self.play_rtmp, (Server))
        p2 = p.apply_async(self.play_m3u8, (Server))
        p3 = p.apply_async(self.play_flv, (Server))
        p.close()
        p.join()
        self.Result.append(p1.get())
        self.Result.append(p2.get())
        self.Result.append(p3.get())

    def push_stop(self):
        f = FFMPEG()
        f.ffmpeg_stop()

    def __init__(self, ip, rtmp_port, http_port, app, stream, mode):
        self.Result = []
        self.Server = [ip, rtmp_port, http_port, app, stream]
        f = FFMPEG()
        if(mode == 'push'):
            f.set_push_config(ip = self.Server[0], port = self.Server[1],app = self.Server[3], stream = self.Server[4])
            f.ffmpeg_push()
            time.sleep(10)
        elif(mode == 'play'):
            self.test_play(self.Server)