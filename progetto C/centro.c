#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "defines.h"



static void aggiungi_pacco(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[3];

	char codice_sp[8];
	int codice_sp_int;
	int num_centro;

	//richiesta informazioni
	printf("\ncodice del pacco: ");
	getInput(8, codice_sp, false);

	//conversione dei valori
	codice_sp_int = atoi(codice_sp);
	num_centro = atoi(conf.username);


	if (!setup_prepared_stmt(&prepared_stmt, "call inserimento_giacenza_pacchi_co(?,?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement inserimento_giacenza_pacchi_co\n", false);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_LONG;
	param[0].buffer = &num_centro;
	param[0].buffer_length = sizeof(num_centro);

	param[1].buffer_type = MYSQL_TYPE_LONG;
	param[1].buffer = &codice_sp_int;
	param[1].buffer_length = sizeof(codice_sp_int);

	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per l'inserimento del pacco in giancenza\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante l'inserimento del pacco in giacenza'\n");
	}
	else{
		printf("pacco con codice: %d aggiunto in giacenza\n", codice_sp_int);
	}

	mysql_stmt_close(prepared_stmt);

}



void conferma_addebita(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[3];

	char codice_sp[8];
	int codice_sp_int;
	int num_centro;
	char costo_effettivo[8];
	float costo_effettivo_float;

	//richiesta informazioni
	printf("\ncodice del pacco: ");
	getInput(8, codice_sp, false);
	printf("inserisci il costo di spedizione effettivo: ");
	getInput(8, costo_effettivo, false);

	//conversione dei valori
	codice_sp_int = atoi(codice_sp);
	num_centro = atoi(conf.username);
	costo_effettivo_float = atof(costo_effettivo);

	if (!setup_prepared_stmt(&prepared_stmt, "call conferma_addebita(?,?,?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement conferma_addebita\n", false);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_LONG;
	param[0].buffer = &codice_sp_int;
	param[0].buffer_length = sizeof(codice_sp_int);
	param[0].is_unsigned = true;

	param[1].buffer_type = MYSQL_TYPE_LONG;
	param[1].buffer = &num_centro;
	param[1].buffer_length = sizeof(num_centro);
	param[1].is_unsigned = true;

	param[2].buffer_type = MYSQL_TYPE_FLOAT;
	param[2].buffer = &costo_effettivo_float;
	param[2].buffer_length = sizeof(costo_effettivo_float);
	param[2].is_unsigned = true;


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per l'inserimento del costo effettivo\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante l'inserimento del costo effettivo'\n");
	}
	else{
		printf("conferma del costo effettivo avvenuta con successo\n");
	}

	mysql_stmt_close(prepared_stmt);
}





void run_as_centro(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[2];

	char op;
	char tipo[46];
	long int codice_co;

	printf("cambio del ruolo in centro operativo\n");

	if(!parse_config("users/centro.json", &conf)){
		fprintf(stderr, "impossibile caricare il ruolo di cliente\n");
		exit(EXIT_FAILURE);
	}

	//funzione di libreria per cambiare il ruolo
	if(mysql_change_user(conn, conf.db_username, conf.db_password, conf.database)){
		fprintf(stderr, "mysql_change_user() failed\n");
		exit(EXIT_FAILURE);
	}




	//verifica il tipo di centro

	if (!setup_prepared_stmt(&prepared_stmt, "call check_tipo_co(?,?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement check_tipo_co\n", false);
	}

	//preparazione parametri
	codice_co = atoi(conf.username);
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_LONG; //IN
	param[0].buffer = &codice_co;
	param[0].buffer_length = sizeof(codice_co);
	param[0].is_unsigned = true;

	param[1].buffer_type = MYSQL_TYPE_STRING; //OUT
	param[1].buffer = &tipo;
	param[1].buffer_length = strlen(tipo);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per la richiesta del tipo di centro\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante la richiesta del tipo di centro\n");
	}
	else {
		//preparo i parametri di output
		memset(param, 0, sizeof(param));

		param[0].buffer_type = MYSQL_TYPE_STRING; //OUT
		param[0].buffer = &tipo;
		param[0].buffer_length = sizeof(tipo);

		if (mysql_stmt_bind_result(prepared_stmt, param)){
			print_stmt_error(prepared_stmt, "impossibile recuperare il parametro di output\n");
			exit(EXIT_FAILURE);
		}

		//recupero il parametro di output
		if (mysql_stmt_fetch(prepared_stmt)){
			print_stmt_error(prepared_stmt, "impossibile bufferizzare i risultati\n");
			exit(EXIT_FAILURE);
		}
	}
	
	mysql_stmt_close(prepared_stmt);


	if (strcmp(tipo, "centro prossimità") == 0){
		char options[3] = {'1', '2', '3'};

		while(true){
		printf("\033[2J\033[H");
		printf("### che cosa vuoi fare? ###\n\n");
		printf("1) aggiungi pacco in giacenza\n");
		printf("2) conferma costo e procedi all'addebito\n");
		printf("3) esci\n");

		op = multiChoice("seleziona un'opzione", options, 3);

		switch(op){
			case '1':
				aggiungi_pacco(conn);
				break;

			case '2':
				conferma_addebita(conn);
				break;

			case '3':
				return; 

			default:
				fprintf(stderr, "Invalid condition at %s:%d\n", __FILE__, __LINE__);
				abort();

		}

		getchar();

		}
	}

	else {
		char options[2] = {'1', '2'};

		while(true){
		printf("\033[2J\033[H");
		printf("### che cosa vuoi fare? ###\n\n");
		printf("1) aggiungi pacco in giacenza\n");
		printf("2) esci\n");

		op = multiChoice("seleziona un'opzione", options, 2);

		switch(op){
			case '1':
				aggiungi_pacco(conn);
				break;

			case '2':
				return; 

			default:
				fprintf(stderr, "Invalid condition at %s:%d\n", __FILE__, __LINE__);
				abort();

		}

		getchar();

		}

	}

}