import MySQLdb
import MySQLdb.cursors
import commands
import os

live_92channel_dir = '/opt/live_sources_92'
getcodec_log_file = '/opt/live_codec_temp.txt'
ffprobe_bin = '/opt/root/ffmpeg/bin/ffprobe'


def insertString(a, b, c, d, e, f, g, h, i, j, k, l, m, n):
    insert_count = "insert into live_info (channel_guid,url_bitrate,url_format,v_codec,v_aspect_ratio,v_frame_rate,v_stream_id,v_resolution,a_codec,a_bitrate,a_sound_track,a_sampling_rate,a_stream_id,channel_type) values ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')" % (
    a, b, c, d, e, f, g, h, i, j, k, l, m, n)
    print
    insert_count
    return insert_count


def getCodec(vod_file):
    cmd = ffprobe_bin + ' ' + vod_file
    status, output = commands.getstatusoutput(cmd)
    return output


def writeLogFile(live_info):
    file = open(getcodec_log_file, 'w+')
    file.write(live_info)
    file.close()


def readLogFile():
    properties = open(getcodec_log_file, 'rb+')
    lines = properties.readlines()
    url_bitrate = ''
    for line in lines:
        line = line.strip('\n')
        if 'Input' in line:
            channel_guid = line.split("/")[3].split("_")[0]
            url_bitrate = line.split("/")[3].split("_")[1].split(".")[0]
            url_format = line.split("/")[3].split("_")[1].split(".")[1].split("'")[0]
            # print channel_guid,url_bitrate,url_format
        if 'Audio' in line:
            a_codec = line.split("Audio:")[1].split("(")[0].strip(' ')
            a_sampling_rate = line.split(",")[1].strip(' ')
            a_sound_track = line.split(",")[2].strip(' ')
            a_stream_id = line.split("[")[0].split("#")[1].strip(' ')
            a_bitrate = line.split(",")[4].strip(' ')

            # print a_codec,a_sampling_rate,a_sound_track,a_stream_id,a_bitrate

        elif 'Video' in line:
            v_codec = line.split("Video:")[1].split("(")[0].strip(' ').replace('h', 'x')
            v_aspect_ratio = line.split(",")[2].split("]")[0].split("DAR")[1].strip(' ')
            v_resolution = line.split(",")[2].split("]")[0].split("[")[0].strip(' ')
            v_stream_id = line.split("[")[0].split("#")[1].strip(' ')
            v_frame_rate = line.split(",")[3].strip(' ')
            # print v_codec,v_aspect_ratio,v_resolution,v_stream_id,v_frame_rate
        if url_bitrate == '1400k':
            channel_type = 0
        elif url_bitrate == '700k':
            channel_type = 1
    insert_str = insertString(channel_guid, url_bitrate, url_format, v_codec, v_aspect_ratio, v_frame_rate, v_stream_id,
                              v_resolution, a_codec, a_bitrate, a_sound_track, a_sampling_rate, a_stream_id,
                              channel_type)
    return insert_str


def listChannelFiles():
    if os.path.exists(live_92channel_dir):
        file_list = os.listdir(live_92channel_dir)
        return file_list
    else:
        return ''


def insertLiveInfoDB():
    live_file_list = listChannelFiles()
    if live_file_list is not '':
        try:
            conn = MySQLdb.connect(host='127.0.0.1', user='root', passwd='db', db='so_ads', port=3306, charset="utf8",
                                   cursorclass=MySQLdb.cursors.DictCursor)
            cur = conn.cursor()
            for live_file in live_file_list:
                file_name = live_92channel_dir + '/' + live_file
                codecInfoOutput = getCodec(file_name)
                writeLogFile(codecInfoOutput)
                insert_sql = readLogFile()
                cur.execute(insert_sql)
                print
                insert_sql

            conn.commit()
            cur.close()
            conn.close()
            return 1

        except MySQLdb.Error, e:
            print
            "Mysql Error %d: %s" % (e.args[0], e.args[1])
            return 0

    else:
        return 0


if __name__ == "__main__":
    insertLiveInfoDB()
