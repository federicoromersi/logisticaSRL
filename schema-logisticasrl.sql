
DROP SCHEMA IF EXISTS logisticasrl;
CREATE SCHEMA logisticasrl;
USE logisticasrl;


CREATE TABLE cliente 
	(
		cf CHAR(16) PRIMARY KEY,
		nome VARCHAR(45) NOT NULL,
		cognome VARCHAR(45) NOT NULL,
		data_di_nascita DATE NOT NULL,
		via_residenza VARCHAR(90) NOT NULL,
		città_residenza VARCHAR(45) NOT NULL,
		cap_residenza INT UNSIGNED NOT NULL, 
		provincia_residenza VARCHAR(45) NOT NULL,
		via_fatturazione VARCHAR(90) NOT NULL,
		città_fatturazione VARCHAR(45) NOT NULL,
		cap_fatturazione INT UNSIGNED NOT NULL,
		provincia_fatturazione VARCHAR(45) NOT NULL
	);



CREATE TABLE carta_di_credito
	(
		numero BIGINT UNSIGNED PRIMARY KEY,
		nome VARCHAR(45) NOT NULL,
		cognome VARCHAR(45) NOT NULL,
		data_di_scadenza DATE NOT NULL,
		codice_cvv SMALLINT UNSIGNED NOT NULL,
		cliente_titolare CHAR(16) NOT NULL,
		FOREIGN KEY (cliente_titolare) REFERENCES cliente(cf)
	);



CREATE TABLE recapiti
	(
		cellulare INT UNSIGNED PRIMARY KEY,
		telefono INT UNSIGNED NOT NULL UNIQUE,
		email VARCHAR(60) NOT NULL UNIQUE,
		cf_cliente CHAR(16) NOT NULL,
		FOREIGN KEY (cf_cliente) REFERENCES cliente(cf),
		check (email regexp'^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9._-]@[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,63}$')
	);



CREATE TABLE coordinate_geo_rec_pacchi
	(
		latitudine FLOAT,
		longitudine FLOAT,
		PRIMARY KEY (latitudine, longitudine)
	);



CREATE TABLE coordinate_cliente
	(
		cf_cliente CHAR(16) PRIMARY KEY REFERENCES cliente(cf),
		latitudine_cgr FLOAT NOT NULL,
		longitudine_cgr FLOAT NOT NULL,
		FOREIGN KEY (latitudine_cgr, longitudine_cgr) REFERENCES coordinate_geo_rec_pacchi(latitudine, longitudine)
	);



CREATE TABLE destinatario
	(
		latitudine FLOAT,
		longitudine FLOAT,
		nome VARCHAR(45) NOT NULL,
		cognome VARCHAR(45) NOT NULL,
		nazione VARCHAR(45) NOT NULL,
		PRIMARY KEY (latitudine, longitudine)
	);



CREATE TABLE spedizione
	(
		codice_spedizione INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		tipo_spedizione VARCHAR(45) NOT NULL,
		cf_cliente CHAR(16) NOT NULL REFERENCES cliente(cf),
		latitudine_des FLOAT NOT NULL,
		longitudine_des FLOAT NOT NULL,
		FOREIGN KEY (latitudine_des, longitudine_des) REFERENCES destinatario(latitudine, longitudine)
	);



CREATE TABLE pacco
	(
		codice_sp INT UNSIGNED PRIMARY KEY,
		peso SMALLINT unsigned NOT NULL,
		lunghezza SMALLINT unsigned NOT NULL,
		larghezza SMALLINT unsigned NOT NULL,
		profondità SMALLINT unsigned NOT NULL,
		nome_categoria VARCHAR(45) DEFAULT NULL,
		FOREIGN KEY (codice_sp) REFERENCES spedizione(codice_spedizione)
	);


CREATE TABLE categoria
	(
		nome VARCHAR(45) PRIMARY KEY,
		prezzo_base FLOAT UNSIGNED NOT NULL,
		dimensione_minima FLOAT NOT NULL,
		dimensione_massima FLOAT NOT NULL
	);


CREATE TABLE fase
	(
		data_ora TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		codice_sp INT UNSIGNED REFERENCES spedizione(codice_spedizione),
		nome VARCHAR(45) NOT NULL,
		PRIMARY KEY (data_ora, codice_sp)
	);


CREATE TABLE affidata_a
	(
		codice_sp INT UNSIGNED REFERENCES spedizione(codice_spedizione),
		codice_co INT UNSIGNED REFERENCES centro_operativo(codice_co),
		PRIMARY KEY (codice_sp, codice_co)
	);



CREATE TABLE centro_operativo
	(
		codice_co INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		via VARCHAR(90) NOT NULL,
		città VARCHAR(45) NOT NULL,
		cap INT UNSIGNED NOT NULL,
		provincia VARCHAR(45) NOT NULL,
		recapito_telefonico INT UNSIGNED NOT NULL UNIQUE,
		latitudine FLOAT NOT NULL,
		longitudine FLOAT NOT NULL,
		nome_responsabile VARCHAR(45) NOT NULL,
		email_segreteria VARCHAR(60) NOT NULL UNIQUE,
		tipo_co VARCHAR(45) NOT NULL
	);



CREATE TABLE pagamento
	(
		codice_co INT UNSIGNED,
		numero_carta BIGINT UNSIGNED,
		costo_effetivo FLOAT UNSIGNED NOT NULL,
		PRIMARY KEY (codice_co, numero_carta),
		FOREIGN KEY (codice_co) REFERENCES centro_operativo(codice_co),
		FOREIGN KEY (numero_carta) REFERENCES carta_di_credito(numero)
	);


CREATE TABLE possiede
	(
		codice_co INT UNSIGNED REFERENCES centro_operativo(codice_co),
		codice_v INT UNSIGNED REFERENCES veicolo(codice_v),
		PRIMARY KEY (codice_co, codice_v)
	);



CREATE TABLE assegnamento
	(
		codice_v INT UNSIGNED REFERENCES veicolo(codice_v),
		codice_sp INT UNSIGNED REFERENCES spedizione(codice_spedizione)
	);



CREATE TABLE veicolo
	(
		codice_v INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		targa CHAR(7) NOT NULL UNIQUE,
		valore_volumetrico FLOAT NOT NULL,
		tipo_veicolo VARCHAR(45) NOT NULL,
		latitudine FLOAT NOT NULL,
		longitudine FLOAT NOT NULL
	);







-- triggers


DELIMITER //
CREATE TRIGGER imposta_categoria_pacco
	BEFORE INSERT ON pacco FOR EACH ROW
    BEGIN
	DECLARE done int DEFAULT FALSE;
	DECLARE var_nome VARCHAR(45);
	DECLARE dim_min FLOAT;
	DECLARE dim_max FLOAT;
	DECLARE somma FLOAT;
	DECLARE cursore1 CURSOR FOR SELECT nome FROM categoria;
    DECLARE cursore2 CURSOR FOR SELECT dimensione_minima FROM categoria;
    DECLARE cursore3 CURSOR FOR SELECT dimensione_massima FROM categoria;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET somma = new.larghezza + new.lunghezza + new.profondità;
	open cursore1;
    open cursore2;
    open cursore3;
	read_loop: loop
		fetch cursore1 into var_nome;
        fetch cursore2 into dim_min;
        fetch cursore3 into dim_max;
		if (somma > dim_min AND somma < dim_max) then
			SET new.nome_categoria = var_nome;
			leave read_loop;
		end if;
	end loop;
	close cursore1; 
    close cursore2;
    close cursore3;
end //
DELIMITER ;



DELIMITER //
CREATE TRIGGER check_grandezza_pacco
	BEFORE INSERT ON pacco FOR EACH ROW
	BEGIN 
	DECLARE somma FLOAT;
	DECLARE volume_massimo FLOAT;
	SET somma = new.larghezza * new.lunghezza * new.profondità;
	SELECT min(valore_volumetrico) FROM veicolo INTO volume_massimo;
	IF (somma > volume_massimo) THEN 
		SIGNAL SQLSTATE "45000";
	END IF;
END //
DELIMITER ;











-- da eliminare

insert into categoria 
values ("media", 40, 100, 1000);

insert into categoria
values ("piccola", 10, 0, 100);  

insert into cliente
values ("abcguri294ktuehv", "federico", "prova", "1999-02-26", "via ciao", "roma", 00012, "roma", "via ciao", "roma", 00012, "roma");

insert into destinatario
values (45, 37, "ciao", "ciao", "italia");

insert into spedizione 
values (13, "nazionale", "abcguri294ktuehv", 45, 37);







