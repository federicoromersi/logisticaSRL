#include <stdio.h>
#include <stdlib.h>
#include <mysql.h>
#include <string.h>



static char const *opt_host_name = "localhost"; /* HOST */
static char const *opt_user_name = "root"; /* USERNAME */
static char const *opt_password = "fede12345"; /* PASSWORD */
static unsigned int opt_port_num = 3306; /* PORT */
static char const *opt_socket_name = NULL; /* SOCKET NAME, DO NOT CHANGE */
static char const *opt_db_name = "logisticasrl"; /* DATABASE NAME */
static unsigned int opt_flags = 0; /* CONNECTION FLAGS, DO NOT CHANGE */





int main (int argc, char **argv){

	MYSQL *conn; //puntatore all'handler di connessione
	MYSQL_RES *res; //contiene il result set
	MYSQL_ROW row;

	// inizializzazione header di connessione
	conn = mysql_init(NULL);
	if (conn == NULL){
		fprintf(stderr, "mysql_init() failed\n");
		exit(EXIT_FAILURE);
	}


	//connessione al server
	if (mysql_real_connect (conn, opt_host_name, opt_user_name, opt_password,
		opt_db_name, opt_port_num, opt_socket_name, opt_flags) == NULL){
		fprintf(stderr, "mysql_real_connect() failed\n");
		mysql_close(conn);
		exit(EXIT_FAILURE);

	}


	//prova tabella database
	if (mysql_query(conn, "SELECT * FROM veicolo") != 0){
		//print_error (conn, "SELECT statement failed");
	}else
		res = mysql_store_result(conn);

	//ottieni il numero delle colonne
	int num_fields = mysql_num_fields(res);


	while ((row = mysql_fetch_row(res)) != NULL){   //scorre le righe
		printf("\n");
		for (int i=0; i < num_fields; i++){  //scorre le colonne
			printf("%s\t", row[i] != NULL ? row[i] : "NULL"); //verifico se è NULL, se è NULL stampo la stringa NULL
		}
	}

	mysql_free_result(res);


	//disconnessione dal server
	mysql_close (conn);
	exit(EXIT_SUCCESS);

}