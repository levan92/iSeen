#!/usr/bin/python           # This is server.py file
import os, sys
import os.path
from socket import *       #Import socket module
import socket
import subprocess
from _thread import *       # Import all from thread
import uuid

s = socket.socket()         # Create a socket object
host = socket.gethostname() # Get local machine name
port = 9000                # Reserve a port for your service.
sockAdd = (host,port)
print ('Set up socket on %s %s' %sockAdd)
s.bind(sockAdd)        # Bind to the port

print ('Listening for connection...')
s.listen(5)                 # Now wait for client connection.

def clientthread(conn):
#infinite loop so that function do not terminate and thread do not end.
      id = uuid.uuid1() #random unique id
      print ('Got connection from', addr, ' (id:',id,')')
      frameFN = "./client_data_cache/frame_" + str(id) + ".jpg"
      labelFN = "./client_data_cache/frame_" + str(id) + ".txt"
      while True:
         imageData = conn.recv(52224)
         if not imageData: break
         #conn.send(b"Got the frame.")
         try:
            with open(frameFN, 'wb') as img:
               img.write(imageData)
         except: continue
         #print ('Wrote jpg file')

         subprocess.call('C:/Users/Administrator/SceneParsing/Executable/SceneParsingScript.bat ../'+frameFN
                         ,shell=True)
         try:
            with open (labelFN,'rb') as labelFile:
               labelData = labelFile.read()
         except: continue

         try: conn.send(labelData)
         except: break
      print('Broke connection with',addr, ' (id:',id,')')
      if os.path.isfile(frameFN):
         os.remove(frameFN)
      if os.path.isfile(labelFN):
         os.remove(labelFN)
 
while True:
#Accepting incoming connections
    conn, addr = s.accept()
#Creating new thread. Calling clientthread function for this function and passing conn as argument.
    start_new_thread(clientthread,(conn,)) #start new thread takes 1st argument as a function name to be run, second is the tuple of arguments to the function.

conn.close()
sock.close()

##while True:
##   conn, addr = s.accept()     # Establish connection with client.
##   print ('Got connection from', addr)
##   
##   while True:
##         imageData = conn.recv(52224)
##         if not imageData: break
##         #print ('-Rcved frame')
##         #conn.send(b"Got the frame.")
##         try:
##            with open('frame.jpg', 'wb') as img:
##               img.write(imageData)
##         except: continue
##         #print ('Wrote jpg file')
##
##         subprocess.call('C:/Users/Administrator/SceneParsing/Executable/SceneParsingScript.bat ../frame.jpg'
##                         ,shell=True)
##         try:
##            with open ('frame.txt','rb') as labelFile:
##               labelData = labelFile.read()
##         except: continue
##
##         try: conn.send(labelData)
##         except: break
##
##   print('broke connection with',addr)
##   conn.close()                # Close the connection
   
   
