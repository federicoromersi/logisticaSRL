#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "defines.h"



void report_giornaliero(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[3];

	int num_sp_accettate = 0, num_sp_consegnate = 0;
	float entrate_tot = 0;


	if (!setup_prepared_stmt(&prepared_stmt, "call report_giornaliero(?, ?, ?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement report_giornaliero\n", false);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_LONG; //OUT
	param[0].buffer = &num_sp_accettate;
	param[0].buffer_length = sizeof(num_sp_accettate);

	param[1].buffer_type = MYSQL_TYPE_LONG; //OUT
	param[1].buffer = &num_sp_consegnate;
	param[1].buffer_length = sizeof(num_sp_consegnate);

	param[2].buffer_type = MYSQL_TYPE_FLOAT; //OUT
	param[2].buffer = &entrate_tot;
	param[2].buffer_length = sizeof(entrate_tot);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per il report giornaliero\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante la richiesta del report giornaliero\n");
	}
	else {
		//preparo i parametri di output
		memset(param, 0, sizeof(param));

		param[0].buffer_type = MYSQL_TYPE_LONG; //OUT
		param[0].buffer = &num_sp_accettate;
		param[0].buffer_length = sizeof(num_sp_accettate);

		param[1].buffer_type = MYSQL_TYPE_LONG; //OUT
		param[1].buffer = &num_sp_consegnate;
		param[1].buffer_length = sizeof(num_sp_consegnate);

		param[2].buffer_type = MYSQL_TYPE_FLOAT; //OUT
		param[2].buffer = &entrate_tot;
		param[2].buffer_length = sizeof(entrate_tot);

		if (mysql_stmt_bind_result(prepared_stmt, param)){
			print_stmt_error(prepared_stmt, "impossibile recuperare il parametro di output\n");
			exit(EXIT_FAILURE);
		}

		//recupero il parametro di output
		if (mysql_stmt_fetch(prepared_stmt)){
			print_stmt_error(prepared_stmt, "impossibile bufferizzare i risultati\n");
			exit(EXIT_FAILURE);
		}

		printf("\nreport delle ultime 24 ore:\n");
		printf("numero di spedizioni accettate: %d\n", num_sp_accettate);
		printf("numero di spedizioni consegnate: %d\n", num_sp_consegnate);
		printf("entrate totali: %.2f €", entrate_tot);
	}
	
	mysql_stmt_close(prepared_stmt);
	
}



void modifica_categoria(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[4];

	char nome[46];
	char dim_min[8], dim_max[8];
	float dim_min_float, dim_max_float = 0;
	char prezzo_base[8];
	float prezzo_base_float;

	printf("\ninserisci i parametri: \n");
	printf("nome della categoria: ");
	getInput(46, nome, false);
	printf("prezzo base per la spedizione: ");
	getInput(8, prezzo_base, false);
	printf("dimensione minima del pacco: ");
	getInput(8, dim_min, false);
	printf("dimensione massima del pacco: ");
	getInput(8, dim_max, false);

	//conversione parametri
	prezzo_base_float = atof(prezzo_base);
	dim_min_float = atof(dim_min);
	dim_max_float = atof(dim_max);


	if (!setup_prepared_stmt(&prepared_stmt, "call modifica_categoria(?, ?, ?, ?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement modifica_categoria\n", false);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_VAR_STRING; //IN
	param[0].buffer = &nome;
	param[0].buffer_length = strlen(nome);

	param[1].buffer_type = MYSQL_TYPE_FLOAT; //IN
	param[1].buffer = &prezzo_base_float;
	param[1].buffer_length = sizeof(prezzo_base_float);

	param[2].buffer_type = MYSQL_TYPE_FLOAT; //IN
	param[2].buffer = &dim_min_float;
	param[2].buffer_length = sizeof(dim_min_float);

	param[3].buffer_type = MYSQL_TYPE_FLOAT; //IN
	param[3].buffer = &dim_max_float;
	param[3].buffer_length = sizeof(dim_max_float);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per la modifica della categoria\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante la richiesta della modifica della categoria\n");
	}
	else {

		printf("categoria modificata con successo!");
	}
	
	mysql_stmt_close(prepared_stmt);
}









void run_as_administrator(MYSQL *conn){

	char op;
	char options[3] = {'1', '2', '3'};

	printf("cambio del ruolo in amministratore\n");

	if(!parse_config("users/amministratore.json", &conf)){
		fprintf(stderr, "impossibile caricare il ruolo di amministratore\n");
		exit(EXIT_FAILURE);
	}

	//funzione di libreria per cambiare il ruolo
	if(mysql_change_user(conn, conf.db_username, conf.db_password, conf.database)){
		fprintf(stderr, "mysql_change_user() failed\n");
		exit(EXIT_FAILURE);
	}


	while(true){
		printf("\033[2J\033[H");
		printf("### che cosa vuoi fare? ###\n\n");
		printf("1) report giornaliero\n");
		printf("2) modifica categoria\n");
		printf("3) esci\n");

		op = multiChoice("seleziona un'opzione", options, 3);

		switch(op){
			case '1':
				report_giornaliero(conn);
				break;

			case '2':
				modifica_categoria(conn);
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