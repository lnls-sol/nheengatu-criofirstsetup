#! /usr/bin/python3
import socket
import subprocess
import time


# Server configuration
HOST = ''
PORT = 60010

VALID_COMMANDS = ['startioc', 'stopioc']

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
                    # Checking greet message
                    data = conn.recv(8)
                    if data !=  b'GREET' + int(PORT).to_bytes(3, byteorder='big'):
                        print('Received wrong greet')
                        msg_to_send = b'ERROR'
                        conn.sendall(msg_to_send)
                    else:
                        print('Received greet')
                        msg_to_send = b'GREET'
                        conn.sendall(msg_to_send)

                        # Wait for command
                        data = conn.recv(1024)
                        msg = data.decode().split(':')

                        print("User:", msg[0])
                        cmd = msg[1]
                        ioc = msg[2]
                        print("cmd:", cmd)
                        print('ioc:', ioc)

                        # If command is not valid, don't execute it
                        if cmd not in VALID_COMMANDS:
                            print('Received wrong command')
                            msg_to_send = b'ERROR'
                            conn.sendall(msg_to_send)
                        else:
                            try:
                                result = subprocess.run(["iocs", cmd, ioc], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                                msg_to_send = result.stdout
                            except Exception as e:
                                print(e)
                                msg_to_send = b'ERROR' + str(e).encode

                            conn.sendall(msg_to_send)

                time.sleep(0.1)

            main_socket.shutdown(socket.SHUT_RDWR)

        except KeyboardInterrupt:
            print("\nExiting...")
            main_socket.shutdown(socket.SHUT_RDWR)
            return


if __name__ == "__main__":
    main()
    time.sleep(1.0)
