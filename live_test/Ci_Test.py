#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 ob767, Inc. All Rights Reserved
#

from Test_Case import TEST_CAST
import smtplib
from email.mime.text import MIMEText
from email.utils import formataddr
import datetime

class CI_TEST():

    def send_email(self, text, sheet, address, email, start_time):
        send_user = 'gao347699598@163.com'
        receive_user = email
        ret = True
        example_num = 0
        success_num = 0
        error = []
        for result in text:
            example_num += 1
            if('验证成功' in result):
                success_num += 1
            elif('验证失败' in result):
                result = result.replace('[1;31;0m', '')
                result = result.replace('[1;32;0m', '')
                error.append(result)
        end_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        text_file = '自动化测试结果：\n\n测试环境：'+sheet+'\n测试开始时间：'+start_time+'\n测试结束时间：'+end_time+'\n测试节点：'+address+'\n回归样例:【Rtmp, M3u8, Flv】\n样例数量：'+str(example_num)+'\n成功率：'+str(success_num/example_num*100)+'%'
        if (len(error)>0):
            text_file += '\n\n-----------------------------------失败节点-----------------------------------\n'
            for text_file_add in error:
                text_file += '\n'+text_file_add
            text_file += '\n\n-----------------------------------------------------------------------------'
        try:
            msg = MIMEText(text_file,'plain' ,'utf-8')
            msg['From'] = formataddr(["CI测试助手", send_user])
            msg['To'] = receive_user
            msg['Subject'] = "自动化测试结果"
            server = smtplib.SMTP_SSL("smtp.163.com", 465)
            server.login(send_user, "Gxob767318000")
            server.sendmail(send_user, receive_user, msg.as_string())
            server.quit()
        except Exception:
            ret = False
        if (ret ==False):
            print('邮件发送失败！')

    def __init__(self, sheet, address, email):
        start_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        if (address == '全量回归'):
            tc = TEST_CAST()
            self.send_email(tc.all_test(sheet), sheet, address, email, start_time)
        else:
            tc = TEST_CAST()
            self.send_email(tc.pop_test(sheet, address, 25), sheet, address, email, start_time)