/* $VER: Mail.comFetcher v0.1 BETA (20.02.2002) © Diego CR
*/
	login="dcr8520@mail.com"
	 pass="#~€#|~€|#"
	faddr="dcr8520@wanadoo.es"
	 smtp="smtp.eresmas.com"

str="action=login&show_frame=Enter&mail_language=us&login="login"&password="pass"&x=150&y=9"
len=length(str)

say 'Loging in....'
if ~open(1,"tcp:www.mail.com/80","RW") then call err("Cant connect to www.mail.com")
call writeln(1,"POST /scripts/common/proxy.main HTTP/1.0")
call writeln(1,"Referer: http://www.mail.com/")
call writeln(1,"Host: www.mail.com")
call writeln(1,"Content-type: application/x-www-form-urlencoded")
call writeln(1,"Content-length: "len)
call writeln(1,"")
call writeln(1,str)
call writeln(1,"a0d"x)
recv=readln(1);if word(recv,2)~=302 then call err("ERROR, the syntax from Mail.com has changed! please warn the author")
do forever;recv=readln(1)
if word(recv,1)="Location:" then LEAVE;END;call close(1)
nurl=word(recv,2);nurl=right(nurl,length(nurl)-7)
pos=pos('/',nurl)-1
nhost=left(nurl,pos);nurl=right(nurl,length(nurl)-pos)

say 'Getting Cookie...'
if ~open(2,"tcp:"||nhost||"/80","RW") then call err("Cant connect to "nhost)
call writeln(2,"GET "nurl" HTTP/1.0")
call writeln(2,"Referer: http://www.mail.com/")
call writeln(2,"Host: "nhost)
call writeln(2,"")
recv=readln(2);if word(recv,2)~=200 then call err("ERROR, the syntax from Mail.com has changed! please warn the author")
do forever;recv=readln(2)
if word(recv,1)="Set-Cookie:" then LEAVE;END;call close(2)

	cookie=word(recv,2);i=0

say 'Cheking Inbox...'
start:
if ~open(1,"tcp:mymail.mail.com/80","RW") then call err("Cant connect to mymail.mail.com !!!");z=0
call writeln(1,"GET /scripts/mail/mailbox.mail?read=yes&login="translate(login,':','@')"&folder=INBOX HTTP/1.1")
call head(1)

do until eof(1)
ln=readln(1)
/***if left(ln,38)=='<p><font color="#000000">You are using' then do;size=word(ln,5);shell command 'run >NIL: say Estás usándo el 'size;say size;exit;END***/
if left(ln,38)=='<td><a href="Javascript:readPopUpMail(' then do;z=1
pos1=pos("'",ln)+1
pos2=pos("')",ln)
url=substr(ln,pos1,pos2-pos1)
url=right(url,length(url)-7)
url=right(url,length(url)-(pos("/",url)-1))
pos1=pos('uid=',url)+3
uid=right(url,length(url)-pos1)
pos2=pos('&',uid)-1
uid=left(uid,pos2)

	i=i+1;say 'Receiving E-Mail #'i'...'
	call open(2,"tcp:mymail.mail.com/80","RW")
	call writeln(2,"GET "url" HTTP/1.1");call head(2)
	do until eof(2)
	ln=readln(2)
	if pos('<td bgcolor="#ececec"><b><font color="#000000">From:</font></b></td>',ln)>0 then do
	 ln=readln(2);pos1=lastpos('">',ln)+2;pos2=pos("</font>",ln)
	 from=substr(ln,pos1,pos2-pos1)
	  if pos('&quot;',from)>0 then do
	  from=right(from,length(from)-6)
	  pos=pos('&quot;',from)-1;name=left(from,pos);end;else name=left(from,pos('&lt;',from)-1)
	  if pos('&lt;',from)>0 then do
	  pos1=pos('&lt;',from)+4
	  pos2=pos('&gt',from)
	  email=substr(from,pos1,pos2-pos1);end;if email="EMAIL" then email=from
	 from='"'name'" <'email'>';END
	if pos('<td width="10%"><font color="#000000"><b>To:</b></td>',ln)>0 then do
	 ln=readln(2);pos1=lastpos('">',ln)+2;pos2=pos("</font>",ln)
	 to=substr(ln,pos1,pos2-pos1);END
	if pos('<td><font color="#000000"><b>Subject: </b></font></td>',ln)>0 then do
	 ln=readln(2);pos1=lastpos('">',ln)+2;pos2=pos("</font>",ln)
	 subj=substr(ln,pos1,pos2-pos1);END
	if pos('<td><font color="#000000"><b>Date: </b></font></td>',ln)>0 then do
	 ln=readln(2);pos1=lastpos('">',ln)+2;pos2=pos("</font>",ln)
	 date=substr(ln,pos1,pos2-pos1);END
	if pos('<table cellpadding="5" cellspacing="0" border="0" width="100%" height="300" class="normaltext"><tr><td valign="top">',ln)>0 then do
	 msg="";do until eof(2)
	 ln=readln(2);if pos('</td></tr></table>',ln)>0 then leave
	 if upper(word(ln,1))="<BR>" then ln=subword(ln,2,words(ln))
	 if pos('<P>',ln)>0 then ln=translate(ln,"d0a"x,"<P>")
	 msg=msg||ln||'0a'x;END;done=1;END
	if done==1 then leave
	end;call close(2)

	say 'Forwarding E-Mail #'i' (From: 'from')...'
	call open(snd,"TCP:"||smtp||"/25","RW");xxx=readln(snd)
	if word(xxx,1)~=220 then call err("ERROR from "smtp": "xxx)
	call writeln(snd,"HELO "smtp);xxx=readln(snd)
	if word(xxx,1)~=250 then call err("ERROR from "smtp": "xxx)
	call writeln(snd,"MAIL FROM: TheArexxFetcher@mail.com");xxx=readln(snd)
	if word(xxx,1)~=250 then call err("ERROR from "smtp": "xxx)
	call writeln(snd,"RCPT TO: "faddr);xxx=readln(snd)
	if word(xxx,1)~=250 then call err("ERROR from "smtp": "xxx)
	call writeln(snd,"DATA");xxx=readln(snd)
	if word(xxx,1)~=354 then call err("ERROR from "smtp": "xxx)
	call writeln(snd,'Received: MESSAGE FORWARDED WITH "Mail.comForward" ©2002 By Diego CR; On 'date()' ('time()')')
	call writeln(snd,"From: "from)
	call writeln(snd,"To: "to)
	call writeln(snd,"Date: "date)
	call writeln(snd,"Subject: "subj)
	call writeln(snd,"Message-Id: <"translate(date(),'-',' ')"/"time()"@TheARexxFetcher4Mail.com>")
	call writeln(snd,"")
	call writeln(snd,msg)
	call writeln(snd,".");xxx=readln(snd)
	if word(xxx,1)~=250 then call err("ERROR from "smtp": "xxx)
	call writeln(snd,"QUIT");xxx=readln(snd)
	if word(xxx,1)~=221 then call err("ERROR from "smtp": "xxx)
	call CLOSE(snd)

	say 'Deleting E-Mail #'i' ('uid')...'
	todel="/scripts/mail/Outblaze.mail?fwdopt=attach&folder_name=Trash&login="||translate(login,':','@')||"&sel_"||uid||"=ON&current_folder=INBOX&order=Newest&ispopupmultiple=0&move_read=&delete_read=yes"
	 len=length(todel)
	call open(2,"tcp:mymail.mail.com/80","RW")
	call writeln(2,"POST /scripts/mail/Outblaze.mail HTTP/1.0")
	call writeln(2,"User-Agent: Mozilla/4.0 (compatible; MSIE 5.0; Win98)")
	call writeln(2,"Host: mymail.mail.com")
	call writeln(2,"Content-Type: application/x-www-form-urlencoded")
	call writeln(2,"Content-Length: "len)
	call writeln(2,"Cookie: "cookie" mail_com_bunjee=")
	call writeln(2,"")
	call writeln(2,todel)
	call writeln(2,"d0a"x)
	xxx=readln(2)
	call close(2)

end
end
if z=1 then call start()
say 'No more E-Mails found.'

exit
head:
call writeln(arg(1),"User-Agent: Mozilla/4.0 (compatible; MSIE 5.0; Win98)")
call writeln(arg(1),"Host: mymail.mail.com")
call writeln(arg(1),"Cookie: "cookie" mail_com_bunjee=")
call writeln(arg(1),"d0a"x)
RETURN
err:
say "[0;1m "arg(1)" [0m"
exit