import os
import datetime
import sys
import ftplib
import gzip
import dateutil.parser

class FtpCli:
    def __init__(self, server):
        self.ftp = ftplib.FTP(server, 'anonymous', '')

    def is_up_to_date(self, path, local_name):
        if not os.path.exists(local_name):
            return False
        local_size = os.path.getsize(local_name)
        local_utime = os.path.getmtime(local_name)
        local_datetime = datetime.datetime.fromtimestamp(local_utime)
        remote_size = self.ftp.size(path)
        remote_date = self.__get_remote_datetime(path)
        if local_size == remote_size and local_datetime == remote_date:
            return True
        print(f'difference in {local_name}', file=sys.stderr, flush=True)
        if not local_size == remote_size:
            print(f'    size (remote) {remote_size:,} != (local) {local_size:,}', file=sys.stderr, flush=True)
        if not local_datetime == remote_date:
            print(f'    time stamp (remote) {remote_date} != (local) {local_datetime}', file=sys.stderr, flush=True)
        return False

    def get(self, remote_path, outfile):
        remote_size = self.ftp.size(remote_path)
        remote_date = self.__get_remote_datetime(remote_path)
        remote_utime = remote_date.timestamp()
        fp = open(outfile, 'wb')
        self.ftp.retrbinary(f'RETR {remote_path}', fp.write)
        fp.close()
        if os.path.exists(outfile):
            local_size = os.path.getsize(outfile)
            if remote_size == local_size:
                os.utime(outfile, (remote_utime, remote_utime))
                if outfile.endswith('.gz'):
                    unzip_file = outfile.replace('.gz', '')
                    self.gz(outfile, unzip_file)
                    os.utime(unzip_file, (remote_utime, remote_utime))
            else:
                print(f'{outfile} size {local_size} != remote {remote_size}', file=sys.stderr)
        else:
            print(f'{outfile} not downloaded', file=sys.stderr)

    def gz(self, file, unzip_file):
        in_fp = gzip.open(file, 'rb')
        out_fp = open(unzip_file, 'wb')
        out_fp.write(in_fp.read())
        in_fp.close()
        out_fp.close()

    def __get_remote_datetime(self, path):
        info = self.ftp.voidcmd(f'MDTM {path}')
        return dateutil.parser.parse(info[4:])
