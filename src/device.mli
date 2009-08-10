(*
 * Copyright (C) 2006-2007 XenSource Ltd.
 * Copyright (C) 2008      Citrix Ltd.
 * Author Vincent Hanquez <vincent.hanquez@eu.citrix.com>
 * Author Dave Scott <dave.scott@eu.citrix.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)
open Device_common

exception Ioemu_failed of string
exception Ioemu_failed_dying

module Generic :
sig
	val rm_device_state : xs:Xs.xsh -> device -> unit
end

module Tap2 :
sig
	exception Mount_failure of string * string * string

	val mount : string -> string -> string
	val unmount : string -> unit
end

module Vbd :
sig
	type mode = ReadOnly | ReadWrite
	val string_of_mode : mode -> string
	val mode_of_string : string -> mode

	type physty = File | Phys | Qcow | Vhd | Aio
	val string_of_physty : physty -> string
	val physty_of_string : string -> physty
	val kind_of_physty : physty -> kind
	val uses_blktap : phystype:physty -> bool

	type devty = CDROM | Disk
	val string_of_devty : devty -> string
	val devty_of_string : string -> devty

	val device_number : string -> int
	val device_name : int -> string
	val device_major_minor : string -> int * int
	val major_minor_to_device : int * int -> string

	val add : xs:Xs.xsh -> hvm:bool -> mode:mode
	       -> virtpath:string -> phystype:physty -> physpath:string
	       -> dev_type:devty
	       -> unpluggable:bool
	       -> diskinfo_pt:bool
	       -> ?protocol:protocol
	       -> ?extra_backend_keys:(string*string) list
	       -> ?backend_domid:Xc.domid
	       -> Xc.domid -> device

	val release : xs:Xs.xsh -> device -> unit
	val media_eject : xs:Xs.xsh -> virtpath:string -> int -> unit
	val media_insert : xs:Xs.xsh -> virtpath:string
	                -> physpath:string -> phystype:physty -> int -> unit
	val media_refresh : xs:Xs.xsh -> virtpath:string -> physpath:string -> int -> unit
	val media_is_ejected : xs:Xs.xsh -> virtpath:string -> int -> bool
	val media_tray_is_locked : xs:Xs.xsh -> virtpath:string -> int -> bool

	val pause : xs:Xs.xsh -> device -> unit
	val unpause : xs:Xs.xsh -> device -> unit

	(* For migration: *)
	val hard_shutdown_request : xs:Xs.xsh -> device -> unit
	val hard_shutdown_complete : xs:Xs.xsh -> device -> string Watch.t
end

module Vif :
sig
	exception Invalid_Mac of string

	val add : xs:Xs.xsh -> devid:int -> netty:Netman.netty
	       -> mac:string -> ?mtu:int -> ?rate:(int64 * int64) option
	       -> ?protocol:protocol -> ?backend_domid:Xc.domid -> Xc.domid
	       -> device
	val plug : xs:Xs.xsh -> netty:Netman.netty
	        -> mac:string -> ?mtu:int -> ?rate:(int64 * int64) option
	        -> ?protocol:protocol -> device
	        -> device
	val release : xs:Xs.xsh -> device -> unit
end

val clean_shutdown : xs:Xs.xsh -> device -> unit
val hard_shutdown  : xs:Xs.xsh -> device -> unit

val can_surprise_remove : xs:Xs.xsh -> device -> bool

module Vcpu :
sig
	val add : xs:Xs.xsh -> devid:int -> int -> unit
	val del : xs:Xs.xsh -> devid:int -> int -> unit
	val set : xs:Xs.xsh -> devid:int -> int -> bool -> unit
	val status : xs:Xs.xsh -> devid:int -> int -> bool
end

module PV_Vnc :
sig
	exception Failed_to_start
	val start : xs:Xs.xsh -> Xc.domid -> int
end

module PCI :
sig
	type t = {
		domain: int;
		bus: int;
		slot: int;
		func: int;
		irq: int;
		resources: (int64 * int64 * int64) list;
		driver: string;
	}
	type dev = int * int * int * int

	exception Cannot_add of (dev list) * exn
	exception Cannot_use_pci_with_no_pciback of t list

	val add : xc:Xc.handle -> xs:Xs.xsh -> hvm:bool -> msitranslate:int
	       -> pci_power_mgmt:int -> dev list -> Xc.domid -> int -> unit
	val release : xc:Xc.handle -> xs:Xs.xsh -> hvm:bool
	       -> dev list -> Xc.domid -> int -> unit
	val reset : xs:Xs.xsh -> device -> unit
	val bind : dev list -> unit
end

module Vfb :
sig
	val add : xc:Xc.handle -> xs:Xs.xsh -> hvm:bool -> ?protocol:protocol -> Xc.domid -> unit
end

module Vkb :
sig
	val add : xc:Xc.handle -> xs:Xs.xsh -> hvm:bool -> ?protocol:protocol -> Xc.domid -> unit
end

module Dm :
sig
	type disp_opt =
		| NONE
		| VNC of bool * string * int * string (* auto-allocate, bind address, port it !autoallocate, keymap *)
		| SDL of string (* X11 display *)

	type info = {
		hvm: bool;
		memory: int64;
		boot: string;
		serial: string;
		vcpus: int;
		usb: string list;
		nics: (string * string * string option) list;
		acpi: bool;
		disp: disp_opt;
		pci_emulations: string list;
		sound: string option;
		power_mgmt: int;
		oem_features: int;
                inject_sci: int;
		videoram: int;
		extras: (string * string option) list;
	}

	val write_logfile_to_log : int -> unit
	val unlink_logfile : int -> unit

	val vnc_port_path : Xc.domid -> string

	val signal : xs:Xs.xsh -> domid:Xc.domid
	          -> string -> string option -> string -> unit

	val start : xs:Xs.xsh -> dmpath:string -> ?timeout:float -> info -> Xc.domid -> int
	val restore : xs:Xs.xsh -> dmpath:string -> ?timeout:float -> info -> Xc.domid -> int
	val stop : xs:Xs.xsh -> Xc.domid -> int -> unit
end
