#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mysql.h>

#include "defines.h"


typedef enum{
	AMMINISTRATORE = 1,
	CLIENTE,
	CENTRO,
	VEICOLO,
	FAILED_LOGIN
}role_t;

 

 struct configuration conf;

 static MYSQL *conn;


static role_t attempt_login(MYSQL *conn, char *username, char *password){

	MYSQL_STMT *login_procedure;	//preparement statement per la procedura di login

	MYSQL_BIND param[3]; //parametri da collegare al preparement statement

	int role = 0;

	if (!setup_prepared_stmt(&login_procedure, "call login(?, ?, ?)", conn)){
		print_stmt_error(login_procedure, "errore inizializzazione login statement\n");
		goto err2;
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_VAR_STRING; //IN
	param[0].buffer = username;
	param[0].buffer_length = strlen(username);

	param[1].buffer_type = MYSQL_TYPE_VAR_STRING; //IN
	param[1].buffer = password;
	param[1].buffer_length = strlen(password);

	param[2].buffer_type = MYSQL_TYPE_LONG; //OUT
	param[2].buffer = &role;
	param[2].buffer_length = sizeof(role);

	if (mysql_stmt_bind_param(login_procedure, param) != 0) {
		print_stmt_error(login_procedure, "impossibile associare i parametri per il login\n");
		goto err;
	}

	//run procedure
	//invia al dbms le informazioni
	if (mysql_stmt_execute(login_procedure) != 0) {
		print_stmt_error(login_procedure, "impossibile eseguire la procedura di login\n");
		goto err;
	}

	//preparo i parametri di output
	memset(param, 0, sizeof(param));
	param[0].buffer_type = MYSQL_TYPE_LONG;
	param[0].buffer = &role;
	param[0].buffer_length = sizeof(role);

	if (mysql_stmt_bind_result(login_procedure, param)){
		print_stmt_error(login_procedure, "impossibile recuperare il parametro di output\n");
		goto err;
	}

	//recupero il parametro di output
	if (mysql_stmt_fetch(login_procedure)){
		print_stmt_error(login_procedure, "impossibile bufferizzare i risultati\n");
		goto err;
	}

	mysql_stmt_close(login_procedure);

	return role; 

	err:
		mysql_stmt_close(login_procedure);
	err2:
		return FAILED_LOGIN;

}




static void registra_nuovo_cliente(){


	MYSQL_STMT *prepared_stmt;	//preparement statement per la procedura di login

	MYSQL_BIND param[22]; //parametri da collegare al preparement statement


	char cf[17], nome_cliente[46], cognome_cliente[46], data_di_nascita[11], via_residenza[91], citta_residenza[46];
	char provincia_residenza[46], via_fatturazione[91], citta_fatturazione[46], provincia_fatturazione[46];
	char nome_intestatario[46], cognome_intestatario[46], data_di_scadenza[11];
	char cap_residenza[6], cap_fatturazione[6], numero[17], codice_cvv[4];
	char longitudine[46], latitudine[46], username[46], password[46];
	int cap_residenza_int, cap_fatturazione_int;
	float longitudine_float, latitudine_float;
	long long int numero_int;
	short int codice_cvv_int;
	MYSQL_TIME data_di_nascita_date, data_di_scadenza_date;

	//richiesta informazioni
	printf("\033[2J\033[H");
	printf("inserisci un username: ");
	getInput(46, username, false);
	printf("inserisci una password: ");
	getInput(46, password, true);
	printf("\ninserisci i tuoi dati: \n");
	printf("codice fiscale: ");
	getInput(17, cf, false);
	printf("nome: ");
	getInput(46, nome_cliente, false);
	printf("cognome: ");
	getInput(46, cognome_cliente, false);
	printf("data di nascita (yyyy-mm-dd): ");
	getInput(11, data_di_nascita, false);
	printf("via di residenza: ");
	getInput(91, via_residenza, false);
	printf("città di residenza: ");
	getInput(17, citta_residenza, false);
	printf("cap della città di residenza: ");
	getInput(6, cap_residenza, false);
	printf("provincia di residenza: ");
	getInput(46, provincia_residenza, false);
	printf("\ninserisci i dati di fatturazione (lasciando vuoto saranno impostati pari a quelli di residenza): \n");
	printf("via di fatturazione: ");
	getInput(91, via_fatturazione, false);
	printf("città di fatturazione: ");
	getInput(46, citta_fatturazione, false); 
	printf("cap di fatturazione: ");
	getInput(6, cap_fatturazione, false); 
	printf("provincia_fatturazione: ");
	getInput(46, provincia_fatturazione, false); 
	printf("\ninserisci i dati della carta di credito:\n");
	printf("numero carta di credito: ");
	getInput(17, numero, false); 
	printf("nome dell'intestatario della carta: ");
	getInput(46, nome_intestatario, false); 
	printf("cognome dell'intestatario della carta: ");
	getInput(46, cognome_intestatario, false); 
	printf("data di scadenza della carta (yyyy-mm-dd): ");
	getInput(11, data_di_scadenza, false); 
	printf("codice_cvv della carta: ");
	getInput(4, codice_cvv, false); 
	printf("\ninserisci i dati per il recupero dei pacchi:\n");
	printf("inserisci la longitudine per il recupero delle spedizioni: ");
	getInput(46, longitudine, false); 
	printf("inserisci la latitudine per il recupero delle spedizioni: ");
	getInput(46, latitudine, false); 



	//conversione dei valori
	numero_int = atoi(numero);
	codice_cvv_int = atoi(codice_cvv);
	cap_residenza_int = atoi(cap_residenza);
	cap_fatturazione_int = atoi(cap_fatturazione);
	longitudine_float = atof(longitudine);
	latitudine_float = atof(latitudine);

	const char s[2] = "-";   
 
   	data_di_scadenza_date.year = atoi(strtok(data_di_scadenza, s));
   	data_di_scadenza_date.month = atoi(strtok(NULL, s));
   	data_di_scadenza_date.day = atoi(strtok(NULL, s));

   	data_di_nascita_date.year = atoi(strtok(data_di_nascita, s));
   	data_di_nascita_date.month = atoi(strtok(NULL, s));
   	data_di_nascita_date.day = atoi(strtok(NULL, s));

   
   	



	if (!setup_prepared_stmt(&prepared_stmt, "call registra_nuovo_cliente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", conn)){
		print_stmt_error(prepared_stmt, "errore inizializzazione registra_nuovo_cliente statement\n");
		exit(EXIT_FAILURE);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_STRING; //IN
	param[0].buffer = cf;
	param[0].buffer_length = strlen(cf);

	param[1].buffer_type = MYSQL_TYPE_VAR_STRING; //IN
	param[1].buffer = nome_cliente;
	param[1].buffer_length = strlen(nome_cliente);

	param[2].buffer_type = MYSQL_TYPE_VAR_STRING; //IN
	param[2].buffer = &cognome_cliente;
	param[2].buffer_length = strlen(cognome_cliente);

	param[3].buffer_type = MYSQL_TYPE_DATE;
	param[3].buffer = &data_di_nascita_date;
	param[3].buffer_length = sizeof(data_di_nascita_date);

	param[4].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[4].buffer = &via_residenza;
	param[4].buffer_length = strlen(via_residenza);

	param[5].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[5].buffer = &citta_residenza;
	param[5].buffer_length = strlen(citta_residenza);

	param[6].buffer_type = MYSQL_TYPE_LONG;
	param[6].buffer = &cap_residenza_int;
	param[6].buffer_length = sizeof(cap_residenza_int);
	param[6].is_unsigned = true;

	param[7].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[7].buffer = &provincia_residenza;
	param[7].buffer_length = strlen(provincia_residenza);

	param[8].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[8].buffer = &via_fatturazione;
	param[8].buffer_length = strlen(via_fatturazione);

	param[9].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[9].buffer = &citta_fatturazione;
	param[9].buffer_length = strlen(citta_fatturazione);

	param[10].buffer_type = MYSQL_TYPE_LONG;
	param[10].buffer = &cap_fatturazione_int;
	param[10].buffer_length = sizeof(cap_fatturazione_int);
	param[10].is_unsigned = true;

	param[11].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[11].buffer = &provincia_fatturazione;
	param[11].buffer_length = strlen(provincia_fatturazione);

	param[12].buffer_type = MYSQL_TYPE_LONGLONG;
	param[12].buffer = &numero_int;
	param[12].buffer_length = sizeof(numero_int);
	param[12].is_unsigned = true;

	param[13].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[13].buffer = &nome_intestatario;
	param[13].buffer_length = strlen(nome_intestatario);

	param[14].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[14].buffer = &cognome_intestatario;
	param[14].buffer_length = strlen(cognome_intestatario);

	param[15].buffer_type = MYSQL_TYPE_DATE;
	param[15].buffer = &data_di_scadenza_date;
	param[15].buffer_length = sizeof(data_di_scadenza_date);

	param[16].buffer_type = MYSQL_TYPE_SHORT;
	param[16].buffer = &codice_cvv_int;
	param[16].buffer_length = sizeof(codice_cvv_int);

	param[17].buffer_type = MYSQL_TYPE_STRING;
	param[17].buffer = &cf;
	param[17].buffer_length = strlen(cf);

	param[18].buffer_type = MYSQL_TYPE_FLOAT;
	param[18].buffer = &latitudine_float;
	param[18].buffer_length = sizeof(latitudine_float);

	param[19].buffer_type = MYSQL_TYPE_FLOAT;
	param[19].buffer = &longitudine_float;
	param[19].buffer_length = sizeof(longitudine_float);

	param[20].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[20].buffer = &username;
	param[20].buffer_length = strlen(username);

	param[21].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[21].buffer = &password;
	param[21].buffer_length = strlen(password);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per registrare il nuovo cliente\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante la registrazione del nuovo cliente\n");
	}

	else{
		printf("\nregistrazione cliente avvenuta con successo!\n");
		
		printf("premi invio per continuare: ");
		
	}

	mysql_stmt_close(prepared_stmt);

}



 int main(){

 	role_t role;
 	char op;
 	char options[2] = {'1', '2'};

 	if (!parse_config("users/login.json", &conf)){
 		fprintf(stderr, "errore nel caricamento della configurazione del login\n");
 		exit(EXIT_FAILURE);
 	}

 	conn = mysql_init (NULL);
 	if (conn == NULL){
 			fprintf(stderr, "mysql_init() failed\n");
 			mysql_close(conn);
 			exit(EXIT_FAILURE);
 	}

 	if (mysql_real_connect(conn, conf.host, conf.db_username, conf.db_password, conf.database, conf.port,   NULL, CLIENT_MULTI_STATEMENTS | CLIENT_MULTI_RESULTS) == NULL){
 		fprintf(stderr, "mysql_real_connect() failed\n");
 		mysql_close(conn);
 		exit(EXIT_FAILURE);
 	}

ripeti:
	printf("\033[2J\033[H");
 	printf("### che cosa vuoi fare? ###\n\n");
 	printf("1) login\n");
	printf("2) registra nuovo cliente\n");

 	
 	op = multiChoice("seleziona un'opzione", options, 2);


 	if (op == '1') {
 		printf("\033[2J\033[H");
 		printf("inserisci le tue credenziali:\n");
 		printf("username: ");
 		getInput(128, conf.username, false);
 		printf("password: ");
 		getInput(128, conf.password, true);

 		role = attempt_login(conn, conf.username, conf.password);

 		switch(role){
 			case AMMINISTRATORE:
 				run_as_administrator (conn);
 				break;

 			case CLIENTE:
 				run_as_client (conn);
 				break;

 			case CENTRO:
 				run_as_centro (conn);
 				break;

 			case VEICOLO:
 				run_as_veicolo (conn);
 				break;

 			case FAILED_LOGIN:
 				fprintf(stderr, "credenziali non valide\n");
 				exit(EXIT_FAILURE);
 				break;

 			default:
				fprintf(stderr, "Invalid condition at %s:%d\n", __FILE__, __LINE__);
				abort();
 		}

 	printf("ciao!\n");

 	mysql_close(conn);
 	}
 	else if (op == '2') {
 		registra_nuovo_cliente();
 		goto ripeti;
 	}


 	return 0;
 }