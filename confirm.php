<html>
<head>
    <title>Confirm</title>
    <meta charset='UTF-8'>
    <meta content='text/html; charset=utf-8' http-equiv='Content-Type'>
    <meta content='width=device-width, initial-scale=1.0' name='viewport'>
</head>
<body>
    <ul class='border-bot'>
        <li>
            <?php
                echo 'Balance: ' . $_POST["btc_amount"];
            ?>
            <br/>
            <?php
                echo 'Address: ' . $_POST["btc_address"];
            ?>

        </li>
    </ul>
</body>
</html>