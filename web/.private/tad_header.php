<?php
function theader() {
echo '
<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <title>TransAtlasDB</title>

        <!-- Fonts -->
        <link href="https://fonts.googleapis.com/css?family=Raleway:100,600" rel="stylesheet" type="text/css">
        
        <!-- Styles -->
        <link rel="STYLESHEET" type="text/css" href="stylesheet.css">
        
        <div class="title sub-md">
            <a href="index.php">TransAtlasDB</a>
        </div>
        <center>
            <div class="links">
                <a href="about.php">About</a>
                <a href="import.php">Data Import</a>
                <a href="sqlquery.php">SQL Query</a>
                <a href="metadata.php">MetaData</a>
                <a href="expression.php">Genes Expression</a>
                <a href="variants.php">Variants</a>
                <a href="https://modupeore.github.com/TransAtlasDB" target="_blank">GitHub</a>
            </div>
        </center>
    </head>
';
}
?>

<?php //Metadata pages
function tmetadata() {
    theader();
?>
    <meta http-equiv="content-type" content="text/html;charset=utf-8" />
    <title>Metadata</title>
    <script type="text/javascript" src="/code.jquery.com/jquery-1.8.3.js"></script>
    <script type="text/javascript">
        function selectAll(source) {
            checkboxes = document.getElementsByName('meta_data[]');
            for(var i in checkboxes)
            checkboxes[i].checked = source.checked;
        }
    </script>
<?php
}
?>

<?php //Database pages
function tsqlquery() {
    theader();
?>
    <meta http-equiv="content-type" content="text/html;charset=utf-8" />
    <title>SQL Query</title>
    <script type="text/javascript" src="/code.jquery.com/jquery-1.8.3.js"></script>
    <link href="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.css" rel="stylesheet" type="text/css" />
    <script src="jquery/jquery-1.11.3.min.js"></script>
    <script src="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js"></script>
    <script language=JavaScript>
        function reload(form) {
            var val=form.fastbit.options[form.fastbit.options.selectedIndex].value;
            self.location='?quest=nosql&fastbit=' + val ;
        }
    </script>
    </script>
<?php
}
?>

<?php //Genes Expression Pages
function texpression() {
  theader();
?>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title>Expression</title>
    <script type="text/javascript" src="//code.jquery.com/jquery-1.8.3.js"></script>
    <link href="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.css" rel="stylesheet" type="text/css" />
    <script src="jquery/jquery-1.11.3.min.js"></script>
    <script src="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js"></script>
    <script language=JavaScript>
        function reload(form) {
            var val=form.organism.options[form.organism.options.selectedIndex].value;
            self.location='?organism=' + val ;
        }
    </script>
    </script>
<?php
}
function tfragment() {
  theader();
?>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title>Expression</title>
    <script type="text/javascript" src="//code.jquery.com/jquery-1.8.3.js"></script>
    <link href="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.css" rel="stylesheet" type="text/css" />
    <script src="jquery/jquery-1.11.3.min.js"></script>
    <script src="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js"></script>
    <script language=JavaScript>
        function reload(form) {
            var val=form.organism.options[form.organism.options.selectedIndex].value;
            self.location='?quest=fragments&organism=' + val ;
        }
    </script>
    </script>
<?php
}
?>

<?php //Variant PAges
function tvariants() {
  theader();
?>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title>Variants</title>
    <script type="text/javascript" src="//code.jquery.com/jquery-1.8.3.js"></script>
    <link href="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.css" rel="stylesheet" type="text/css" />
    <script src="jquery/jquery-1.11.3.min.js"></script>
    <script src="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js"></script>
    <script language=JavaScript>
        function reload(form) {
            var val=form.organism.options[form.organism.options.selectedIndex].value;
            self.location='?organism=' + val ;
        }
    </script>
<?php
}
function tvarisum() {
  theader();
?>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title>Variants</title>
    <script type="text/javascript" src="//code.jquery.com/jquery-1.8.3.js"></script>
    <link href="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.css" rel="stylesheet" type="text/css" />
    <script src="jquery/jquery-1.11.3.min.js"></script>
    <script src="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js"></script>
    <script language=JavaScript>
        function reload(form) {
            var val=form.organism.options[form.organism.options.selectedIndex].value;
            self.location='?quest=summary&organism=' + val ;
        }
    </script>
<?php
}
function tvarichrom() {
  theader();
?>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title>Variants</title>
    <script type="text/javascript" src="//code.jquery.com/jquery-1.8.3.js"></script>
    <link href="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.css" rel="stylesheet" type="text/css" />
    <script src="jquery/jquery-1.11.3.min.js"></script>
    <script src="jquery/jquery-ui-1.11.4.custom/jquery-ui.min.js"></script>
    <script language=JavaScript>
        function reload(form) {
            var val=form.organism.options[form.organism.options.selectedIndex].value;
            self.location='?quest=chrom&organism=' + val ;
        }
    </script>
<?php
}
?>
