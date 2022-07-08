#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mysql.h>
#include <unistd.h>

#include "defines.h"



void run_as_veicolo(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[3];
	char targa[8];

	float latitudine = 45, longitudine = 13;

	printf("cambio del ruolo in veicolo\n");

	if(!parse_config("users/veicolo.json", &conf)){
		fprintf(stderr, "impossibile caricare il ruolo di veicolo\n");
		exit(EXIT_FAILURE);
	}

	//funzione di libreria per cambiare il ruolo
	if(mysql_change_user(conn, conf.db_username, conf.db_password, conf.database)){
		fprintf(stderr, "mysql_change_user() failed\n");
		exit(EXIT_FAILURE);
	}

	strcpy(targa, conf.username);


	printf("\033[2J\033[H");


	while(true){

		if (!setup_prepared_stmt(&prepared_stmt, "call aggiorna_posizione(?, ?, ?)", conn)){
			finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement aggiorna_posizione\n", false);
		}

		//preparazione parametri
		memset(param, 0, sizeof(param));

		param[0].buffer_type = MYSQL_TYPE_FLOAT; //IN
		param[0].buffer = &latitudine;
		param[0].buffer_length = sizeof(latitudine);

		param[1].buffer_type = MYSQL_TYPE_FLOAT; //IN
		param[1].buffer = &longitudine;
		param[1].buffer_length = sizeof(longitudine);

		param[2].buffer_type = MYSQL_TYPE_STRING; //IN
		param[2].buffer = &targa;
		param[2].buffer_length = strlen(targa);


		if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
			finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per l'aggiornamento della posizione\n", true);
		}

		//run procedure
		if (mysql_stmt_execute(prepared_stmt) != 0){
			print_stmt_error(prepared_stmt, "errore durante la richiesta per l'aggiornamento della posizione\n");
		}
		else {
			printf("aggiornamento posizione del veicolo... \n");
			printf("latitudine: %f\n", latitudine);
			printf("longitudine: %f\n\n", longitudine);
		}

		mysql_stmt_close(prepared_stmt);

		sleep(5);
	}
}