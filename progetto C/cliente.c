#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "defines.h"


char cf[17];


static void crea_nuovo_ordine(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[12];

	char latitudine[46], longitudine[46], nome[46], cognome[46], nazione[46];
	char peso[5], lunghezza[5], larghezza[5], profondita[5];
	float latitudine_float, longitudine_float, costo_stimato = 0;
	short int peso_int, lunghezza_int, larghezza_int, profondita_int;
	int codice_sp;
	//richiesta informazioni
	printf("\nlatitudine del destinatario: ");
	getInput(46, latitudine, false);
	printf("longitudine del destinatario: ");
	getInput(46, longitudine, false);
	printf("nome del destinatario: ");
	getInput(46, nome, false);
	printf("cognome del destinatario: ");
	getInput(46, cognome, false);
	printf("nazione del destinatario: ");
	getInput(46, nazione, false);
	printf("peso del pacco: ");
	getInput(5, peso, false);
	printf("lunghezza del pacco: ");
	getInput(5, lunghezza, false);
	printf("larghezza del pacco: ");
	getInput(5, larghezza, false);
	printf("profondita del pacco: ");
	getInput(5, profondita, false);


	//conversione dei valori
	peso_int = atoi(peso);
	lunghezza_int = atoi(lunghezza);
	larghezza_int = atoi(larghezza);
	profondita_int = atoi(profondita);
	latitudine_float = atof(latitudine);
	longitudine_float = atof(longitudine);


	if (!setup_prepared_stmt(&prepared_stmt, "call crea_nuovo_ordine(?,?,?,?,?,?,?,?,?,?,?,?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement crea_nuovo_ordine\n", false);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_FLOAT;
	param[0].buffer = &latitudine_float;
	param[0].buffer_length = sizeof(latitudine_float);

	param[1].buffer_type = MYSQL_TYPE_FLOAT;
	param[1].buffer = &longitudine_float;
	param[1].buffer_length = sizeof(longitudine_float);

	param[2].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[2].buffer = &nome;
	param[2].buffer_length = strlen(nome);

	param[3].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[3].buffer = &cognome;
	param[3].buffer_length = strlen(cognome);

	param[4].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[4].buffer = &nazione;
	param[4].buffer_length = strlen(nazione);

	param[5].buffer_type = MYSQL_TYPE_STRING;
	param[5].buffer = &cf;
	param[5].buffer_length = strlen(cf);

	param[6].buffer_type = MYSQL_TYPE_SHORT;
	param[6].buffer = &peso_int;
	param[6].buffer_length = sizeof(peso_int);

	param[7].buffer_type = MYSQL_TYPE_SHORT;
	param[7].buffer = &lunghezza_int;
	param[7].buffer_length = sizeof(lunghezza_int);

	param[8].buffer_type = MYSQL_TYPE_SHORT;
	param[8].buffer = &larghezza_int;
	param[8].buffer_length = sizeof(larghezza_int);

	param[9].buffer_type = MYSQL_TYPE_SHORT;
	param[9].buffer = &profondita_int;
	param[9].buffer_length = sizeof(profondita_int);

	param[10].buffer_type = MYSQL_TYPE_FLOAT;	//OUT
	param[10].buffer = &costo_stimato;
	param[10].buffer_length = sizeof(costo_stimato);

	param[11].buffer_type = MYSQL_TYPE_LONG;	//OUT
	param[11].buffer = &codice_sp;
	param[11].buffer_length = sizeof(codice_sp);

	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per la creazione dell'ordine\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante la creazione del nuovo ordine\n");
	}
	else{
		//preparo i parametri di output
		memset(param, 0, sizeof(param));
		param[0].buffer_type = MYSQL_TYPE_FLOAT;
		param[0].buffer = &costo_stimato;
		param[0].buffer_length = sizeof(costo_stimato);

		param[1].buffer_type = MYSQL_TYPE_LONG;	
		param[1].buffer = &codice_sp;
		param[1].buffer_length = sizeof(codice_sp);

		if (mysql_stmt_bind_result(prepared_stmt, param)){
			print_stmt_error(prepared_stmt, "impossibile recuperare il parametro di output\n");
			exit(EXIT_FAILURE);
		}

		//recupero il parametro di output
		if (mysql_stmt_fetch(prepared_stmt)){
			print_stmt_error(prepared_stmt, "impossibile bufferizzare i risultati\n");
			exit(EXIT_FAILURE);
		}
		printf("\nregistrazione del nuovo ordine avvenuta con successo!\n");
		printf("codice di spedizione: %d\n", codice_sp);
		printf("prezzo stimato per la spedizione: %.2f €\n", costo_stimato);
	}

	mysql_stmt_close(prepared_stmt);
}



void aggiungi_recapiti(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[4];

	char cellulare[11], telefono[11];
	long int cellulare_int, telefono_int;
	char email[61];

	printf("\ninserisci i tuoi dati: \n");
	printf("numero di cellulare: ");
	getInput(11, cellulare, false);
	printf("numero di telefono: ");
	getInput(11, telefono, false);
	printf("email: ");
	getInput(61, email, false);

	//conversione parametri
	cellulare_int = atoi(cellulare);
	telefono_int = atoi(telefono);

	if (!setup_prepared_stmt(&prepared_stmt, "call aggiungi_recapiti(?, ?, ?, ?)", conn)){
		print_stmt_error(prepared_stmt, "errore inizializzazione aggiungi_recapiti statement\n");
		exit(EXIT_FAILURE);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_LONG;
	param[0].buffer = &cellulare_int;
	param[0].buffer_length = sizeof(cellulare_int);
	param[0].is_unsigned = true;

	param[1].buffer_type = MYSQL_TYPE_LONG;
	param[1].buffer = &telefono_int;
	param[1].buffer_length = sizeof(telefono_int);
	param[1].is_unsigned = true;

	param[2].buffer_type = MYSQL_TYPE_VAR_STRING;
	param[2].buffer = &email;
	param[2].buffer_length = strlen(email);

	param[3].buffer_type = MYSQL_TYPE_STRING;
	param[3].buffer = &cf;
	param[3].buffer_length = strlen(cf);

	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per l'aggiunta dei recapiti'\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante l'aggiunta dei recapiti'\n");
	}
	else {
		printf("recapiti aggiunti con successo!\n");
	}

	mysql_stmt_close(prepared_stmt);

}


void visualizza_posizione_pacco (MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[4];

	char codice_sp[10];
	long int codice_sp_int;
	float latitudine = 0, longitudine = 0;

	printf("\ninserisci il codice di spedizione: ");
	getInput(10, codice_sp, false);


	//conversioni parametri
	codice_sp_int = atoi(codice_sp);


	if (!setup_prepared_stmt(&prepared_stmt, "call visualizza_posizione_pacco(?, ?, ?, ?)", conn)){
		print_stmt_error(prepared_stmt, "errore inizializzazione visualizza_posizione_pacco statement\n");
		exit(EXIT_FAILURE);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_LONG;
	param[0].buffer = &codice_sp_int;
	param[0].buffer_length = sizeof(codice_sp_int);
	param[0].is_unsigned = true;

	param[1].buffer_type = MYSQL_TYPE_STRING;
	param[1].buffer = &cf;
	param[1].buffer_length = strlen(cf);

	param[2].buffer_type = MYSQL_TYPE_FLOAT; //OUT
	param[2].buffer = &latitudine;
	param[2].buffer_length = sizeof(latitudine);

	param[3].buffer_type = MYSQL_TYPE_FLOAT; //OUT
	param[3].buffer = &longitudine;
	param[3].buffer_length = sizeof(longitudine);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per la visualizzazione delle coordinate del pacco\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante visualizzazione delle coordinate del pacco\n");
	}
	else {

		//preparo i parametri di output
		memset(param, 0, sizeof(param));

		param[0].buffer_type = MYSQL_TYPE_FLOAT;
		param[0].buffer = &latitudine;
		param[0].buffer_length = sizeof(latitudine);

		param[1].buffer_type = MYSQL_TYPE_FLOAT;	
		param[1].buffer = &longitudine;
		param[1].buffer_length = sizeof(longitudine);

		if (mysql_stmt_bind_result(prepared_stmt, param)){
			print_stmt_error(prepared_stmt, "impossibile recuperare il parametro di output\n");
			exit(EXIT_FAILURE);
		}

		//recupero il parametro di output
		if (mysql_stmt_fetch(prepared_stmt)){
			print_stmt_error(prepared_stmt, "impossibile bufferizzare i risultati\n");
			exit(EXIT_FAILURE);
		}

		if (latitudine == 0){
			printf("non puoi visualizzare la posizione per questa spedizione\n");
			goto exit2;
		}

		printf("il pacco si trova in posizione: \n");
		printf("latitudine: %f\n", latitudine);
		printf("longitudine: %f\n", longitudine);

	}
exit2:
	mysql_stmt_close(prepared_stmt);

}



void stato_spedizione(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[2];

	int status;
	long int codice_sp_int; 
	char codice_sp[8];
	char nome[46];
	MYSQL_TIME data_ora;


	//richiesta informazioni
	printf("\ncodice di spedizione: ");
	getInput(8, codice_sp, false);

	//conversione dei valori
	codice_sp_int = atoi(codice_sp);


	if (!setup_prepared_stmt(&prepared_stmt, "call stato_spedizione(?, ?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement stato_spedizione\n", false);
	}


	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_LONG;
	param[0].buffer = &codice_sp_int;
	param[0].buffer_length = sizeof(codice_sp_int);
	param[0].is_unsigned = true;

	param[1].buffer_type = MYSQL_TYPE_STRING;
	param[1].buffer = &cf;
	param[1].buffer_length = strlen(cf);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per la visualizzazione dello stato della spedizione\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante la visualizzazione dello stato della spedizione'\n");
	}

	else{	

		if (mysql_stmt_store_result(prepared_stmt)) {
			fprintf(stderr, " mysql_stmt_execute(), 1 failed\n");
			fprintf(stderr, " %s\n", mysql_stmt_error(prepared_stmt));
			exit(0);
		}

		if (mysql_stmt_num_rows(prepared_stmt) < 1){
			printf("non puoi visualizzare lo stato di questa spedizione\n");
			goto exit;
		}


		//preparazione parametri
		memset(param, 0, sizeof(param));

		param[0].buffer_type = MYSQL_TYPE_VAR_STRING;
		param[0].buffer = &nome;
		param[0].buffer_length = sizeof(nome);

		param[1].buffer_type = MYSQL_TYPE_TIMESTAMP;
		param[1].buffer = &data_ora;
		param[1].buffer_length = sizeof(data_ora);

		if(mysql_stmt_bind_result(prepared_stmt, param)) {
		finish_with_stmt_error(conn, prepared_stmt, "Unable to bind column parameters\n", true);
		}

		/* assemble course general information */
		while (true) {
			status = mysql_stmt_fetch(prepared_stmt);

			if (status == 1 || status == MYSQL_NO_DATA)
				break;

			printf("--> %-40s %d/%d/%d  %d:%d:%d\n", nome, data_ora.day,data_ora.month,data_ora.year,data_ora.hour,data_ora.minute,data_ora.second);

		}
exit:
		status = mysql_stmt_next_result(prepared_stmt);
		if (status > 0)
			finish_with_stmt_error(conn, prepared_stmt, "Unexpected condition", true);

	}

	mysql_stmt_close(prepared_stmt);

}



char *return_cf(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[2];

	//richiesta codice fiscale

	if (!setup_prepared_stmt(&prepared_stmt, "call return_cf(?,?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement return_cf\n", false);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_STRING; //IN
	param[0].buffer = &conf.username;
	param[0].buffer_length = strlen(conf.username);

	param[1].buffer_type = MYSQL_TYPE_STRING; //OUT
	param[1].buffer = &cf;
	param[1].buffer_length = sizeof(cf);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per la richiesta del codice fiscale\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante la richiesta del codice fiscale\n");
	}
	else {
		//preparo i parametri di output
		memset(param, 0, sizeof(param));

		param[0].buffer_type = MYSQL_TYPE_STRING; //OUT
		param[0].buffer = &cf;
		param[0].buffer_length = sizeof(cf);

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
	
	return cf;

}



void aggiorna_coordinate_recupero_pacco(MYSQL *conn){

	MYSQL_STMT *prepared_stmt;
	MYSQL_BIND param[3];

	char latitudine[10], longitudine[10];
	float latitudine_float, longitudine_float;


	//richiesta informazioni
	printf("\ninserisci le nuove coordinate per il recupero dei pacchi:\n");
	printf("latitudine: ");
	getInput(10, latitudine, false);
	printf("longitudine: ");
	getInput(10, longitudine, false);


	//conversione dei valori
	latitudine_float = atof(latitudine);
	longitudine_float = atof(longitudine);

	//richiesta codice fiscale

	if (!setup_prepared_stmt(&prepared_stmt, "call aggiorna_coordinate_recupero_pacco(?,?,?)", conn)){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile inizializzare lo statement aggiorna_coordinate_recupero_pacco\n", false);
	}

	//preparazione parametri
	memset(param, 0, sizeof(param));

	param[0].buffer_type = MYSQL_TYPE_STRING; //OUT
	param[0].buffer = &cf;
	param[0].buffer_length = strlen(cf);

	param[1].buffer_type = MYSQL_TYPE_FLOAT; //OUT
	param[1].buffer = &latitudine_float;
	param[1].buffer_length = sizeof(latitudine_float);

	param[2].buffer_type = MYSQL_TYPE_FLOAT; //OUT
	param[2].buffer = &longitudine_float;
	param[2].buffer_length = sizeof(longitudine_float);


	if (mysql_stmt_bind_param(prepared_stmt, param) != 0){
		finish_with_stmt_error(conn, prepared_stmt, "impossibile fare il bind dei parametri per l'aggiornamento delle coordinate\n", true);
	}

	//run procedure
	if (mysql_stmt_execute(prepared_stmt) != 0){
		print_stmt_error(prepared_stmt, "errore durante l'aggiornamento delle coordinate\n");
	}
	else {
		printf("coordinate aggiornate con successo");
	}
	
	mysql_stmt_close(prepared_stmt);

}







void run_as_client(MYSQL *conn){

	char op;
	char options[6] = {'1', '2', '3', '4', '5', '6'};

	printf("cambio del ruolo in cliente\n");

	if(!parse_config("users/cliente.json", &conf)){
		fprintf(stderr, "impossibile caricare il ruolo di cliente\n");
		exit(EXIT_FAILURE);
	}

	//funzione di libreria per cambiare il ruolo
	if(mysql_change_user(conn, conf.db_username, conf.db_password, conf.database)){
		fprintf(stderr, "mysql_change_user() failed\n");
		exit(EXIT_FAILURE);
	}

	strcpy(cf, return_cf(conn));

	while(true){
		printf("\033[2J\033[H");
		printf("### che cosa vuoi fare? ###\n\n");
		printf("1) crea un nuovo ordine\n");
		printf("2) aggiungi recapiti\n");
		printf("3) visualizza coordinate correnti del pacco\n");
		printf("4) visualizza stato spedizione\n");
		printf("5) aggiorna le coordinate per il recupero dei pacchi\n");
		printf("6) esci\n");

		op = multiChoice("seleziona un'opzione", options, 6);

		switch(op){
			case '1':
				crea_nuovo_ordine(conn);
				break;

			case '2':
				aggiungi_recapiti(conn);
				break;

			case '3':
				visualizza_posizione_pacco(conn);
				break;

			case '4':
				stato_spedizione(conn);
				break;

			case '5':
				aggiorna_coordinate_recupero_pacco(conn);
				break;

			case '6':
				return; 

			default:
				fprintf(stderr, "Invalid condition at %s:%d\n", __FILE__, __LINE__);
				abort();

		}

		getchar();

	}
}