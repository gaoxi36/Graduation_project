#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# ffmpeg Push-Play Tool Script:
# Packaging FFMPEG class
# Provides setting functions:
# Set_push_config() parameter setting:
# file (full name of file, current location)
# vcodec (video decoding)
# acodec (audio decoding)
# IP (push stream address)
# port (push port)
# Vhost (domain)
# app (device name)
# stream (stream name)
#
# Set_play_config() parameter setting:
# IP (play-down address)
# port (play port)
# Vhost (domain)
# app (device name)
# stream (stream name)
#
# Provided to the push function: ffmpeg_push()
# Provided to the push termination function: ffmpeg_stop()
#
# Provided play function:
# ffplay_rtmp_play() RTMP play
# ffplay_m3u8_play() HLS play
# ffplay_flv_play() flv play
#
#
#ffmpeg推拉流工具脚本：
#打包FFMPEG类
#提供设置函数：
# set_push_config()不定参数设置:
#   file(文件全名，当前位置)
#   vcodec(视频解码方式)
#   acodec(音频解码方式)
#   ip(推流地址)
#   port(推流端口)
#   vhost(推流域名)
#   app(设备名称)
#   stream(流名称)
#
# set_play_config()不定参数设置：
#   ip(拉流地址)
#   port(拉流端口)
#   vhost(拉流域名)
#   app(设备名称)
#   stream(流名称)
#
#提供给推流函数：ffmpeg_push()
#提供推流终止函数：ffmpeg_stop()
#
#提供拉流函数：
#   ffplay_rtmp_play()rtmp拉流
#   ffplay_m3u8_play()hls拉流
#   ffplay_flv_play()flv拉流
#
# Copyright (c) 2019 jd.com, Inc. All Rights Reserved
#

import os
import sys
import subprocess
import time
import datetime

class FFMPEG :

    os.chdir(os.path.dirname(sys.argv[0]))
    __push_config = {
        'file': 'test.mp4',
        'vcodec': 'copy',
        'acodec': 'copy',
        'ip': '',
        'port': '',
        'vhost':'',
        'app': '',
        'stream': ''
    }

    __play_config = {
        'ip': '',
        'port': '',
        'vhost': '',
        'app': '',
        'stream': ''
    }



    def set_push_config(self,**setconfig):
        set_push_warning = '\033[1;33;0m[Ffmpeg]-[class_FFMPEG]-[set_push_config]-WARNING:\033[1;33;0m'
        set_push_error = '\033[1;32;0m[Ffmpeg]-[class_FFMPEG]-[set__push_config]-ERROR:\033[1;32;0m'
        for key, value in setconfig.items():
            if(key == 'file'):
                self.__push_config['file'] = value
            elif(key == 'vcodec'):
                self.__push_config['vcodec'] = value
            elif(key == 'acodec'):
                self.__push_config['acodec'] = value
            elif (key == 'ip'):
                self.__push_config['ip'] = value
            elif (key == 'port'):
                self.__push_config['port'] = value
            elif (key == 'vhost'):
                self.__push_config['vhost'] = value
            elif(key == 'app'):
                self.__push_config['app'] = value
            elif(key == 'stream'):
                self.__push_config['stream'] = value
            else:
                print(set_push_warning,'\033[1;0mset failed, %s is not the config\033[1;0m\n' %key)

        # print('\033[0mffmpeg config:{\nfile=%s\nvcodec=%s\nacodec=%s\nip=%s\nport=%s\nvhost=%s\nlive=%s\nstream=%s}\033[0m\n'
        #       %(self.__push_config['file'],self.__push_config['vcodec'],self.__push_config['acodec'],
        #         self.__push_config['ip'],self.__push_config['port'],self.__push_config['vhost'],
        #         self.__push_config['app'],self.__push_config['stream']))



    def set_play_config(self,**setconfig):
        set_play_warning = '\033[1;33;0m[Ffmpeg]-[class_FFMPEG]-[set_play_config]-WARNING:\033[1;33;0m'
        set_play_error = '\033[1;32;0m[Ffmpeg]-[class_FFMPEG]-[set__play_config]-ERROR:\033[1;32;0m'
        for key, value in setconfig.items():
            if(key == 'ip'):
                self.__play_config['ip'] = value
            elif (key == 'port'):
                self.__play_config['port'] = value
            elif(key == 'vhost'):
                self.__play_config['vhost'] = value
            elif(key == 'app'):
                self.__play_config['app'] = value
            elif(key == 'stream'):
                self.__play_config['stream'] = value
            else:
                print(set_play_warning,'\033[1;0mset failed, %s is not the config\033[1;0m\n' %key)

        # print('\033[0mffplay config:{\nip=%s\nport=%s\nvhost=%s\napp=%s\nstream=%s}\033[0m\n'
        #       %(self.__play_config['ip'],self.__push_config['port'],self.__play_config['vhost'],
        #         self.__play_config['app'],self.__play_config['stream']))



    def ffmpeg_push(self):
        subprocess.Popen("ffmpeg -re -i %s -vcodec %s -acodec %s -f flv rtmp://%s:%s/%s?vhost=%s/%s"
                  %(self.__push_config['file'],self.__push_config['vcodec'],self.__push_config['acodec'],
                    self.__push_config['ip'],self.__push_config['port'],self.__push_config['app'],
                    self.__push_config['vhost'],self.__push_config['stream']))



    def ffplay_rtmp_play(self):
        p = subprocess.Popen("ffplay rtmp://%s:%s/%s?vhost=%s/%s"
                  %(self.__play_config['ip'],self.__play_config['port'],self.__play_config['app'],
                    self.__play_config['vhost'],self.__play_config['stream']))
        time.sleep(8)
        NowTime = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        if (subprocess.Popen.poll(p) == 0):
            return ("\033[1;31;0m%s [%s]-[%s]-Rtmp-[%s]-[%s]:验证失败\033[1;32;0m"
                    %(NowTime, self.__push_config['ip'], self.__push_config['vhost'],
                      self.__play_config['ip'], self.__play_config['vhost']))
        else:
            p.kill()
            return ("\033[1;32;0m%s [%s]-[%s]-Rtmp-[%s]-[%s]:验证成功\033[1;32;0m"
                    % (NowTime, self.__push_config['ip'], self.__push_config['vhost'],
                       self.__play_config['ip'], self.__play_config['vhost']))



    def ffplay_m3u8_play(self):
        p = subprocess.Popen("ffplay http://%s:%s/%s/%s.m3u8"
                   %(self.__play_config['vhost'],self.__play_config['port'],self.__play_config['app'],
                     self.__play_config['stream']))
        time.sleep(8)
        NowTime = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        if (subprocess.Popen.poll(p) == 0):
           return ("\033[1;31;0m%s [%s]-[%s]-M3u8-[%s]-[%s]:验证失败\033[1;32;0m"
                   % (NowTime, self.__push_config['ip'], self.__push_config['vhost'],
                      self.__play_config['ip'], self.__play_config['vhost']))
        else:
            p.kill()
            return ("\033[1;32;0m%s [%s]-[%s]-M3u8-[%s]-[%s]:验证成功\033[1;32;0m"
                    % (NowTime, self.__push_config['ip'], self.__push_config['vhost'],
                       self.__play_config['ip'], self.__play_config['vhost']))



    def ffplay_flv_play(self):
        p = subprocess.Popen("ffplay http://%s:%s/%s/%s.flv"
                  %(self.__play_config['vhost'],self.__play_config['port'],self.__play_config['app'],
                    self.__play_config['stream']))
        time.sleep(8)
        NowTime = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        if (subprocess.Popen.poll(p) == 0):
            return("\033[1;31;0m%s [%s]-[%s]-Flv-[%s]-[%s]:验证失败\033[1;32;0m"
                   %(NowTime, self.__push_config['ip'], self.__push_config['vhost'],
                     self.__play_config['ip'], self.__play_config['vhost']))
        else:
            p.kill()
            return ("\033[1;32;0m%s [%s]-[%s]-Flv-[%s]-[%s]:验证成功\033[1;32;0m"
                    % (NowTime, self.__push_config['ip'], self.__push_config['vhost'],
                       self.__play_config['ip'], self.__play_config['vhost']))



    def ffmpeg_stop(self):
        os.system("taskkill /f /t /im ffmpeg.exe")