#!/usr/bin/env ruby
# MIT licence

if ARGV.empty?
puts "Usage: #{$0} [-d|-e]

Options:
  -d Decrypt data using one of your private keys
  -e Encrypt data using a public key
"
exit
end

require 'tempfile'

def decrypt
  puts 'Paste the crypted message:'
  msg = ''
  started = false
  $stdin.each_line do |line|
    started = line =~ /^-----BEGIN PGP MESSAGE-----/ unless started
    msg += line if started
    break if line =~ /-----END PGP MESSAGE-----$/
  end
  fmsg = Tempfile.new('msg')
  fmsg.write(msg)
  fmsg.close
  puts `gpg -d #{fmsg.path}`
  fmsg.unlink
end

def encrypt
  puts 'Paste the public key:'
  key = ''
  started = false
  $stdin.each_line do |line|
    started = line =~ /^-----BEGIN PGP PUBLIC KEY BLOCK-----/ unless started
    key += line if started
    break if line =~ /-----END PGP PUBLIC KEY BLOCK-----$/
  end
  puts "\nType your message (CTRL+D to stop):"
  msg = ''
  $stdin.each_line do |line|
    msg += line
  end
  fkey = Tempfile.new('public.key')
  fkey.write(key)
  fkey.close
  fmsg = Tempfile.new('msg')
  fmsg.write(msg)
  fmsg.close
  gpg = `gpg --keyid-format long --import #{fkey.path} 2>&1`
  fkey.unlink
  keyid = /([A-F0-9]{16})/.match(gpg)[1]
  puts
  system "gpg --always-trust -a -o - -e -r #{keyid} #{fmsg.path}"
  fmsg.unlink
end

case ARGV[0]
  when '-d' then decrypt
  when '-e' then encrypt
end
