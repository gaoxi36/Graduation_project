#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 jd.com, Inc. All Rights Reserved
#

from Ffmpeg import FFMPEG
from multiprocessing import Pool
import time

class PUSH_PLAY:

    def play_rtmp(self, *Server):
        f = FFMPEG()
        f.set_push_config(ip = Server[0], vhost = Server[1])
        f.set_play_config(ip = Server[4], port = '41800',
                          vhost = Server[5], app = Server[6], stream = Server[7])
        return f.ffplay_rtmp_play()

    def play_m3u8(self, *Server):
        f = FFMPEG()
        f.set_push_config(ip = Server[0], vhost = Server[1])
        f.set_play_config(ip = Server[4], port = '41801',
                          vhost = Server[5], app = Server[6], stream = Server[7])
        return f.ffplay_m3u8_play()

    def play_flv(self, *Server):
        f = FFMPEG()
        f.set_push_config(ip = Server[0], vhost = Server[1])
        f.set_play_config(ip = Server[4], port = '41801',
                          vhost = Server[5], app = Server[6], stream = Server[7])
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

    def __init__(self, push_ip, push_vhost, push_app, push_stream,
                 play_ip, play_vhost, play_app, play_stream, type):
        if(type == 1 or type == 10):
            self.Result = []
            self.Server = [push_ip, push_vhost , push_app, push_stream,
                           play_ip, play_vhost, play_app, play_stream, type]
            f = FFMPEG()
            f.set_push_config(ip = self.Server[0], port = '41800', vhost = self.Server[1],
                              app = self.Server[2], stream = self.Server[3])
            f.ffmpeg_push()
            time.sleep(10)
            self.test_play(self.Server)
            f.ffmpeg_stop()
        elif(type == 2 or type == 11):
            self.Result = []
            self.Server = [push_ip, push_vhost, push_app, push_stream,
                           play_ip, play_vhost, play_app, play_stream, type]
            self.test_play(self.Server)
        elif(type == 3 or type == 12):
            self.Result = []
            self.Server0 = ['', '', '', '',
                           play_ip, play_vhost, play_app, play_stream, type]
            self.Server1 = [push_ip, push_vhost, push_app, push_stream,
                            play_ip, play_vhost, play_app, play_stream, type]
            self.test_play(self.Server0)
            f = FFMPEG()
            f.set_push_config(ip=self.Server1[0], port='41800', vhost=self.Server1[1],
                              app=self.Server1[2], stream=self.Server1[3])
            f.ffmpeg_push()
            time.sleep(10)
            self.test_play(self.Server1)
            f.ffmpeg_stop()