class_name Certificate
extends Node

# https://www.youtube.com/watch?v=gcopx40pwvY
const x509_cert_filename = "X509_Certificate.crt"
const x509_key_filename = "x509_Key.key"
const X509_cert_path = "res://Certificate/" + x509_cert_filename
const X509_key_path = "res://Certificate/" + x509_key_filename

const  CN = "kuma-gee.com"
const  O = "KumaGee" # organization
const  C = "AT" # country
const  not_before = "20251110000000"
const  not_after = "20500210000000"

static func CreateX509Cert():
	if FileAccess.file_exists(X509_cert_path):
		return
	
	if DirAccess.dir_exists_absolute("res://Certificate"):
		pass
	else:
		DirAccess.make_dir_absolute("res://Certificate")
	
	var CNOC = "CN=" + CN + " ,O=" + O + ",C=" + C
	var crypto = Crypto.new()
	var crypto_key = crypto.generate_rsa(4096)
	var X509_cert = crypto.generate_self_signed_certificate(crypto_key, CNOC, not_before, not_after)
	X509_cert.save(X509_cert_path)
	crypto_key.save(X509_key_path)
	print("Creating new certificate")

static func get_certificate():
	return load(X509_cert_path)

static func get_key():
	return load(X509_key_path)
