#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 ob767, Inc. All Rights Reserved
#

from Push_Play import PUSH_PLAY
import xlrd
import random
import sys
import time

class TEST_CAST:

    def all_test(self, sheet):
        Result = []
        relay = []
        edge = []
        file = xlrd.open_workbook(r'dev.xlsx')
        dev_file = file.sheet_by_name(sheet)
        i = 2
        while i < dev_file.nrows:
            row = dev_file.row_values(i)
            if(row[0][-2:] == '中转'):
                relay.append(row)
            else:
                edge.append(row)
            i+=1
        #relay-push, edge-play
        for relay_push in relay:
            relay_name = relay_push[0]
            relay_ip = relay_push[2]
            relay_rtmp_port = relay_push[3]
            relay_http_port = relay_push[4]
            push = PUSH_PLAY(relay_ip, relay_rtmp_port, relay_http_port, 'live', 'BadApple', 'push')
            for edge_play in edge:
                edge_address = edge_play[0]
                edge_ip = edge_play[2]
                edge_rtmp_port = edge_play[3]
                edge_http_port = edge_play[4]
                play = PUSH_PLAY(edge_ip, edge_rtmp_port, edge_http_port, 'live', 'BadApple', 'play')
                for i in play.Result:
                    i = i.replace(edge_rtmp_port, edge_address)
                    i = i.replace(edge_http_port, edge_address)
                    i = i[:i.find(']')+1] + '-[' + relay_name + ']-' + i[i.find(']')+1:]
                    Result.append(i)
            push.push_stop()
        #edge-push, edge-play(random)
            for pop in edge:
                for R in self.pop_test(sheet, pop[0], 1):
                    Result.append(R)
                time.sleep(5)
        for i in Result:
            print(i)
        return Result

    def pop_test(self, sheet, pop_name, test_num):
        Result = []
        relay = []
        edge = []
        file = xlrd.open_workbook(r'dev.xlsx')
        dev_file = file.sheet_by_name(sheet)
        i = 2
        while i < dev_file.nrows:
            row = dev_file.row_values(i)
            if (row[0][-2:] == '中转'):
                relay.append(row)
            else:
                edge.append(row)
            i += 1
        #edge-push, edge-play(random)
        ispop = 'false'
        for edge_push in edge:
            if (edge_push[0] == pop_name):
                ispop = 'true'
                edge_name = edge_push[0]
                edge_ip = edge_push[2]
                edge_rtmp_port = edge_push[3]
                edge_http_port = edge_push[4]
                break
        if (ispop == 'false'):
            print(pop_name+' is a not true pop')
            sys.exit(0)
        else:
            push = PUSH_PLAY(edge_ip, edge_rtmp_port, edge_http_port, 'live', 'BadApple', 'push')
            pop_list = []
            edge_num = len(edge)
            while len(pop_list)<test_num:
                pop_num = random.randint(0,edge_num-1)
                iscpnum = 'false'
                for i in pop_list:
                    if (i == pop_num):
                        iscpnum = 'true'
                        break
                if (iscpnum == 'false'):
                    pop_list.append(pop_num)
            for i in pop_list:
                edge_play = edge[i]
                edge_address = edge_play[0]
                edge_ip = edge_play[2]
                edge_rtmp_port = edge_play[3]
                edge_http_port = edge_play[4]
                play = PUSH_PLAY(edge_ip, edge_rtmp_port, edge_http_port, 'live', 'BadApple', 'play')
                for i in play.Result:
                    i = i.replace(edge_rtmp_port, edge_address)
                    i = i.replace(edge_http_port, edge_address)
                    i = i[:i.find(']')+1]+'-['+edge_name+']-'+i[i.find(']')+1:]
                    Result.append(i)
            push.push_stop()
            for i in Result:
                print(i)
            return Result