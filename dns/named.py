#pip3 install dnspython
#pip3 install dnslib
from dns.resolver import Resolver
from dnslib import DNSRecord, QTYPE, RD, SOA, DNSHeader, RR, A
import socket

import logging
import logging.config
import re
import yaml
import argparse


arg = argparse.ArgumentParser('DNS server proxy')
arg.add_argument("--config", "-c",
                 default="dns_config.yaml",
                 type=argparse.FileType('r'),
                 help="configuration file"
                 )
args = arg.parse_args()

#get  config
with open(args.config.name, "r", encoding="utf8") as f:dns_config = yaml.safe_load(f)
with open(dns_config['server']['logConfig'], "r", encoding="utf8") as f: logging_config = yaml.safe_load(f)

logging.config.dictConfig(logging_config)
logger = logging.getLogger("dns")

dns_resolver = Resolver()
dns_resolver.nameservers =  dns_config['dns_config']['resolver']
service_domain = dns_config['dns_config']['domains']
listenIP = dns_config['server']['listenIP']
listenPort = dns_config['server']['listenPort']

def check_ip(ipAddr): 
    import sys 
    addr=ipAddr.strip().split('.') 
    if len(addr) != 4: 
        logger.error("[ %s ] check ip address failed!.." % ipAddr )
        return False
    for i in range(4): 
        try: 
            addr[i]=int(addr[i])
        except: 
            logger.error("[ %s ] check ip address failed!" % ipAddr)
            return False
        if addr[i]<=255 and addr[i]>=0:
            pass
        else: 
            logger.error("[ %s ] check ip address failed!" % ipAddr)
            return False 
        i+=1
    else: 
        return True


def get_ip_from_domain(domain):
    domain = domain.lower().strip()
    for i in service_domain:
        if i.split('.')[0] == '*':
           pattern = i.replace('*','\w+').replace('.','\.')
           cf_domain = re.findall(pattern,domain)
           if len(cf_domain) == 0 : continue
           else: cf_domain = cf_domain[0]
        else: cf_domain = i
        if cf_domain in domain:
            ip_tmp = domain.replace('.'+cf_domain,'')
            if re.match(r'\d+-\d+',ip_tmp): ip = ip_tmp.replace('-','.')
            else: ip = ip_tmp
            if check_ip(ip): return ip
            else: return None
    try:
        return dns_resolver.resolve(domain, 'A')[0].to_text()
    except:
        return None

def reply_for_not_found(income_record):
    header = DNSHeader(id=income_record.header.id, bitmap=income_record.header.bitmap, qr=1)
    header.set_rcode(0)  # 3 DNS_R_NXDOMAIN, 2 DNS_R_SERVFAIL, 0 DNS_R_NOERROR
    record = DNSRecord(header, q=income_record.q)
    return record

def reply_for_A(income_record, ip, ttl=None):
    r_data = A(ip)
    header = DNSHeader(id=income_record.header.id, bitmap=income_record.header.bitmap, qr=1)
    domain = income_record.q.qname
    query_type_int = QTYPE.reverse.get('A') or income_record.q.qtype
    record = DNSRecord(header, q=income_record.q, a=RR(domain, query_type_int, rdata=r_data, ttl=ttl))
    return record

def dns_handler(s, message, address):
    try:
        income_record = DNSRecord.parse(message)
    except:
        logger.error('from %s, parse error' % address)
        return
    try:
        qtype = QTYPE.get(income_record.q.qtype)
    except:
        qtype = 'unknown'
    domain = str(income_record.q.qname).strip('.')
    info = '%s -- %s, from %s' % (qtype, domain, address)
    if qtype == 'A':
        ip = get_ip_from_domain(domain)
        if ip:
            response = reply_for_A(income_record, ip=ip, ttl=60)
            s.sendto(response.pack(), address)
            return logger.info(info+' IN '+ip)
    # at last
    response = reply_for_not_found(income_record)
    s.sendto(response.pack(), address)
    logger.info(info)

def main():
    udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_sock.bind((listenIP, listenPort))
    logger.info('dns server is started')
    while True:
        try:
            message, address = udp_sock.recvfrom(8192)
            dns_handler(udp_sock, message, address)
        except Exception as err:
            logger.error('Client or resolver server actively disconnects')
            logger.error(err)

if __name__ == '__main__':
    main()
