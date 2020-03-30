#!/usr/bin/python

import socket
import subprocess
import time


# Server configuration
HOST = ''
PORT = 60010


def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as main_socket:
        # main_socket.close()
        # return
        try:
            main_socket.bind((HOST, PORT))

            while True:
                # Wait for a client connection
                main_socket.listen()
                conn, addr = main_socket.accept()

                with conn:
                    print('Connected by', addr)
                    data = conn.recv(1024)
                    msg = data.decode().split(' ')

                    print(msg)
                    if msg[0] == 'exit':
                        conn.sendall(b'exit Iocsd')
                        break

                    try:
                        result = subprocess.run(["iocs"] + msg, stdout=subprocess.PIPE,
                                                stderr=subprocess.STDOUT)
                        msg_to_send = result.stdout
                    except Exception as e:
                        print(e)
                        msg_to_send = b'ERROR'

                    conn.sendall(msg_to_send)

                time.sleep(0.05)

            main_socket.shutdown(socket.SHUT_RDWR)

        except KeyboardInterrupt:
            print("\nExiting...")
            main_socket.shutdown(socket.SHUT_RDWR)
            return


if __name__ == "__main__":
    main()
    time.sleep(0.5)
