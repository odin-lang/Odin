package nbio

import "core:net"

Network_Error  :: net.Network_Error
Accept_Error   :: net.Accept_Error
Dial_Error     :: net.Dial_Error
Send_Error     :: net.Send_Error
TCP_Send_Error :: net.TCP_Send_Error
UDP_Send_Error :: net.UDP_Send_Error
Recv_Error     :: net.Recv_Error
TCP_Recv_Error :: net.TCP_Recv_Error
UDP_Recv_Error :: net.UDP_Recv_Error
Listen_Error   :: net.Listen_Error
Create_Socket_Error :: net.Create_Socket_Error

Address_Family  :: net.Address_Family
Socket_Protocol :: net.Socket_Protocol

Address     :: net.Address
IP4_Address :: net.IP4_Address
IP6_Address :: net.IP6_Address

Endpoint :: net.Endpoint

TCP_Socket :: net.TCP_Socket
UDP_Socket :: net.UDP_Socket
Any_Socket :: net.Any_Socket

IP4_Any      :: net.IP4_Any
IP6_Any      :: net.IP6_Any
IP4_Loopback :: net.IP4_Loopback
IP6_Loopback :: net.IP6_Loopback

family_from_endpoint :: net.family_from_endpoint
bind                 :: net.bind
bound_endpoint       :: net.bound_endpoint
parse_endpoint       :: net.parse_endpoint
endpoint_to_string   :: net.endpoint_to_string
