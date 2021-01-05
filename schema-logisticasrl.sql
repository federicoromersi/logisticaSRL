
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
		check (email regexp'^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9._-]@[a-zA-Z0-9]
			  [a-zA-Z0-9._-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,63}$')
	);



CREATE TABLE coordinate_geo_rec_pacchi
	(
		latitudine FLOAT,
		longitudine FLOAT,
		-- flag BOOLEAN,
		PRIMARY KEY (latitudine, longitudine)
	);



CREATE TABLE coordinate_cliente
	(
		cf_cliente CHAR(16) PRIMARY KEY REFERENCES cliente(cf),
		latitudine_cgr FLOAT NOT NULL,
		longitudine_cgr FLOAT NOT NULL,
		flag BOOLEAN,
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
		tipo_spedizione VARCHAR(45) DEFAULT NULL,
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
		ordine_spedizione INT UNSIGNED,
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
		tipo_co VARCHAR(45) NOT NULL,
		check (email_segreteria regexp '^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9._-]@[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,63}$')

	);



CREATE TABLE pagamento
	(
		codice_co INT UNSIGNED,
		numero_carta BIGINT UNSIGNED,
		costo_effettivo FLOAT UNSIGNED NOT NULL,
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
		codice_sp INT UNSIGNED REFERENCES spedizione(codice_spedizione),
		PRIMARY KEY (codice_sp)
	);



CREATE TABLE veicolo
	(
		codice_v INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		targa CHAR(7) NOT NULL UNIQUE,
		valore_volumetrico FLOAT NOT NULL,
		tipo_veicolo VARCHAR(45) NOT NULL,
		latitudine FLOAT NOT NULL,
		longitudine FLOAT NOT NULL,
		check (targa regexp '^[A-Za-z]{2}[0-9]{3}[A-Za-z]{2}$')
	);


CREATE TABLE giacenza_pacchi_co
	(
		codice_co INT UNSIGNED REFERENCES centro_operativo(codice_co),
		codice_sp INT UNSIGNED REFERENCES spedizione(codice_spedizione),
		PRIMARY KEY (codice_co, codice_sp)
	);



-- functions

DELIMITER //

CREATE FUNCTION distanza(lat1 FLOAT, long1 FLOAT, lat2 FLOAT, long2 FLOAT)
returns FLOAT
DETERMINISTIC
BEGIN
	DECLARE r INT;
	DECLARE dist FLOAT;
	SET lat1 = RADIANS(lat1);
	SET long1 = RADIANS(long1);
	SET lat2 = RADIANS(lat2);
	SET long2 = RADIANS(long2);
	SET r = 6371;
	SET dist = 2*r* asin( sqrt( POWER(sin((lat2-lat1)/2),2) + cos(lat1) *cos(lat2) *POWER(sin((long2-long1)/2),2) ) );
	return dist;
END //

DELIMITER ;









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


DELIMITER //
CREATE TRIGGER assegnamento_veicolo
	BEFORE INSERT ON assegnamento FOR EACH ROW
	BEGIN
	DECLARE num INT;
	SELECT count(*) FROM assegnamento WHERE codice_sp = new.codice_sp INTO num;
	IF (num >= 1) THEN
		SIGNAL SQLSTATE "45000";
	END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER scadenza_carta_di_credito
	BEFORE INSERT ON carta_di_credito FOR EACH ROW
	BEGIN
	IF ( CURRENT_TIMESTAMP > new.data_di_scadenza) THEN
		SIGNAL SQLSTATE "45000";
	END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER inserimento_indirizzo_fatturazione
	BEFORE INSERT ON cliente FOR EACH ROW
	BEGIN
	IF (new.via_fatturazione IS NULL and new.città_fatturazione IS NULL and new.cap_fatturazione IS NULL
		and new.provincia_fatturazione IS NULL) THEN
		SET new.via_fatturazione = new.via_residenza;
		SET new.città_fatturazione = new.città_residenza;
		SET new.cap_fatturazione = new.cap_residenza;
		SET new.provincia_fatturazione = new.provincia_residenza;
	END IF;
END //
DELIMITER ;





DELIMITER //
CREATE TRIGGER affidamento_centro_operativo
AFTER INSERT ON spedizione FOR EACH ROW
	BEGIN
	DECLARE dist FLOAT;
	DECLARE ind INT;
	DECLARE co1 INT;
	DECLARE co2 INT;
	DECLARE co3 INT;
	DECLARE co4 INT;
	DECLARE co5 INT;
	DECLARE co6 INT;
	SET ind = 1;
	-- calcolo centro prossimità più vicino all'indirizzo di recupero
	SELECT codice_co
	FROM spedizione JOIN coordinata_ritiro_pacco_cliente on cf_cliente = cf_cl,
		 centro_operativo
	WHERE codice_spedizione = new.codice_spedizione AND
		  tipo_co = "centro prossimità" AND
		  distanza(latitudine, longitudine, 
		  latitudine_cl, longitudine_cl) = (SELECT min(distanza(latitudine, longitudine, 
		  											latitudine_cl, longitudine_cl))
					  						FROM spedizione JOIN coordinata_ritiro_pacco_cliente on cf_cliente = cf_cl,
					  	   						  centro_operativo
		  									WHERE codice_spedizione = new.codice_spedizione
		  										  AND tipo_co = "centro prossimità") INTO co1;


	-- inserimento centro di prossimità addetto al ritiro del pacco
	INSERT INTO affidata_a VALUES (new.codice_spedizione, co1, ind);
	SET ind = ind + 1;
	-- inserisce il pacco all'interno di giacenza_pacchi_co per "avvertire" il centro di prossimità
	-- che dovrà occuparsi del ritiro del pacco
	INSERT INTO giacenza_pacchi_co VALUES (co1, new.codice_spedizione);
	
	-- calcolo distanza cliente-destinazione
	SELECT distanza(latitudine_des, longitudine_des, latitudine_cl, longitudine_cl)
	FROM spedizione JOIN coordinata_ritiro_pacco_cliente ON cf_cliente = cf_cl
	WHERE codice_spedizione = new.codice_spedizione INTO dist;

	-- se la distanza è minore di 40 sarà lo stesso centro di prossimità che ha ritirato
	-- il pacco ad occuparsi della consegna
	IF ( dist > 40) THEN
		-- cerco il centro di smistamento nazionale più vicino al centro di prossimità
		-- che ha ritirato il pacco
		SELECT c2.codice_co
		FROM centro_operativo AS c1, centro_operativo AS c2 
		WHERE c1.codice_co = co1 AND c2.codice_co != co1 AND c2.tipo_co = "centro smistamento nazionale" 
			AND distanza(c1.latitudine, c1.longitudine,
			c2.latitudine, c2.longitudine) = (SELECT min(distanza(c1.latitudine, c1.longitudine,
													c2.latitudine, c2.longitudine))
											  FROM centro_operativo AS c1, centro_operativo AS c2 
											  WHERE c1.codice_co = co1 AND c2.codice_co != co1
											 	 AND c2.tipo_co = "centro smistamento nazionale") INTO co2;

		INSERT INTO affidata_a VALUES (new.codice_spedizione, co2, ind);
		SET ind = ind + 1 ;


		-- verifico se la spedizione è del tipo internazionale
		IF ( (SELECT tipo_spedizione FROM spedizione WHERE codice_spedizione = new.codice_spedizione) = "internazionale") THEN 
			-- cerco il centro di smistamento internazionale più vicino al centro di smistamento 
			-- nazionale precedentemente scelto
			SELECT c2.codice_co
			FROM centro_operativo AS c1, centro_operativo AS c2 
			WHERE c1.codice_co = co2 AND c2.codice_co != co2 AND c2.tipo_co = "centro smistamento internazionale"
				AND distanza(c1.latitudine, c1.longitudine,
				c2.latitudine, c2.longitudine) = (SELECT min(distanza(c1.latitudine, c1.longitudine,
													c2.latitudine, c2.longitudine))
											  	FROM centro_operativo AS c1, centro_operativo AS c2 
											  	WHERE c1.codice_co = co2 AND c2.codice_co != co2
											  		AND c2.tipo_co = "centro smistamento internazionale") INTO co3;

			INSERT INTO affidata_a VALUES (new.codice_spedizione, co3, ind);
			SET ind = ind + 1;



			-- cerco il centro di smistamento nazionale più vicino al destinatario
			SELECT codice_co
			FROM spedizione, centro_operativo
			WHERE spedizione.codice_spedizione = new.codice_spedizione AND
				codice_co != co3 AND
				tipo_co = "centro smistamento internazionale" AND
				distanza(latitudine, longitudine, latitudine_des, longitudine_des) = (SELECT min(distanza(latitudine, longitudine, latitudine_des, longitudine_des))
																					  FROM spedizione, centro_operativo
																					  WHERE spedizione.codice_spedizione = new.codice_spedizione AND
																					  		codice_co != co3 AND
																					  		tipo_co = "centro smistamento internazionale") INTO co4;


			INSERT INTO affidata_a VALUES (new.codice_spedizione, co4, ind);
			SET ind = ind + 1;
																					
		END IF;

		-- cerco il centro di smistamento nazionale più vicino al destinatario
		SELECT codice_co
		FROM spedizione, centro_operativo
		WHERE spedizione.codice_spedizione = new.codice_spedizione AND
			codice_co != co2 AND
			tipo_co = "centro smistamento nazionale" AND
			distanza (latitudine, longitudine, latitudine_des, longitudine_des) = (SELECT min(distanza (latitudine, longitudine, latitudine_des, longitudine_des))
																				   FROM spedizione, centro_operativo
																				   WHERE spedizione.codice_spedizione = new.codice_spedizione AND
																				   		codice_co != co2 AND
																					  	tipo_co = "centro smistamento nazionale") INTO co5;

		INSERT INTO affidata_a VALUES (new.codice_spedizione, co5, ind);
		SET ind = ind + 1;


	 	-- cerco il centro di prossimità più vicino al destinatario
	 	SELECT codice_co
		FROM spedizione, centro_operativo
		WHERE spedizione.codice_spedizione = new.codice_spedizione AND
			codice_co != co1 AND
			tipo_co = "centro prossimità" AND
			distanza (latitudine, longitudine, latitudine_des, longitudine_des) = (SELECT min(distanza (latitudine, longitudine, latitudine_des, longitudine_des))
																				   FROM spedizione, centro_operativo
																				   WHERE spedizione.codice_spedizione = new.codice_spedizione AND
																				   		codice_co != co1 AND
																					  	tipo_co = "centro prossimità") INTO co6;

		INSERT INTO affidata_a VALUES (new.codice_spedizione, co6, ind);

	END IF;

END//

DELIMITER ;


/* OPPURE 
	SELECT codice_co
	FROM spedizione JOIN cliente ON cf_cliente = cf 
		 JOIN coordinate_cliente as cc ON cc.cf_cliente = cf,
		 centro_operativo
	WHERE flag = TRUE AND
		  distanza(latitudine, longitudine, 
		  latitudine_cgr, longitudine_cgr) = (SELECT min(distanza(latitudine, longitudine, 
		  											latitudine_cgr, longitudine_cgr))
					  						 FROM spedizione JOIN cliente ON cf_cliente = cf 
					  	  					 JOIN coordinate_cliente as cc ON cc.cf_cliente = cf,
					  	   						  centro_operativo);
*/			



DELIMITER //

CREATE TRIGGER verifica_tipo_spedizione
BEFORE INSERT ON spedizione FOR EACH ROW
BEGIN
	DECLARE nazione_des VARCHAR(45);
	SELECT nazione
	FROM destinatario
	WHERE new.latitudine_des = latitudine AND new.longitudine_des  = longitudine INTO nazione_des;

	IF (nazione_des = "italia") THEN
		SET new.tipo_spedizione = "nazionale";
	ELSE 
		SET new.tipo_spedizione = "internazionale";
	END IF;
END //

DELIMITER ;



DELIMITER //

CREATE TRIGGER gestione_pacco_co
AFTER INSERT ON giacenza_pacchi_co FOR EACH ROW
BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE cod_v INT;
	DECLARE spaz_disp FLOAT;
	-- cursore che scorre tutti i furgoni appartenenti ad un centro operativo
	DECLARE cursore1 CURSOR FOR SELECT v.codice_v FROM possiede AS p JOIN veicolo as v ON p.codice_v = v.codice_v
							    WHERE codice_co = new.codice_co and tipo_veicolo = "furgone";
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	-- verifica se il centro operativo è il primo ad occuparsi del pacco, in questo caso deve quindi occuparsi 
	-- anche del ritiro
	IF ((SELECT ordine_spedizione FROM affidata_a WHERE codice_co = new.codice_co AND codice_sp = new.codice_sp) = 1) THEN
		-- verifica se esiste un veicolo appartenente al centro operativo con abbastanza spazio disponibile per il pacco
		open cursore1;
		read_loop2: loop
			fetch cursore1 INTO cod_v;
			(SELECT spazio_disponibile FROM spazio_disponibile_veicolo WHERE codice_veicolo = cod_v) INTO spaz_disp;
			IF (spaz_disp > (SELECT lunghezza*larghezza*profondità FROM pacco WHERE codice_sp = new.codice_sp)) THEN
				-- se esiste un veicolo con spazio disponibile inserisce il seguente assegnamento
				INSERT INTO assegnamento VALUES (cod_v, new.codice_sp);
				LEAVE read_loop2;
			ELSEIF done THEN
				LEAVE read_loop2;
			END IF;
		END loop;
		-- se non esiste il veicolo aggiorna la fase del pacco in "attesa di recupero"
		INSERT INTO fase VALUES (CURRENT_TIMESTAMP, new.codice_sp, "attesa di recupero");
	END IF;

END //

DELIMITER ;







/*funzione che passati in input latitudine e longitudine di 2 posti
restituisce la distanza tra i 2 punti*/





	



-- views

CREATE VIEW spazio_disponibile_veicolo (codice_veicolo, spazio_disponibile) AS
SELECT veicolo.codice_v, valore_volumetrico-COALESCE(sum(lunghezza*larghezza*profondità),0)
FROM veicolo LEFT join assegnamento on veicolo.codice_v = assegnamento.codice_v
	LEFT join pacco on assegnamento.codice_sp = pacco.codice_sp
GROUP BY veicolo.codice_v;


CREATE VIEW costo_spedizione (codice_spedizione, stima_costo, costo_effettivo) AS 
SELECT pacco.codice_sp, max(prezzo_base*peso), max(costo_effettivo)
FROM pacco JOIN categoria ON nome = nome_categoria
	JOIN spedizione ON pacco.codice_sp = spedizione.codice_spedizione
	LEFT JOIN affidata_a ON spedizione.codice_spedizione = affidata_a.codice_sp
	LEFT JOIN centro_operativo ON affidata_a.codice_co = centro_operativo.codice_co
	LEFT JOIN pagamento ON centro_operativo.codice_co = pagamento.codice_co
-- WHERE pagamento.codice_co IS NOT NULL
group by pacco.codice_sp;


CREATE VIEW posizione_pacco (codice_spedizione, latitudine, longitudine) AS
SELECT pacco.codice_sp, latitudine, longitudine
FROM pacco JOIN assegnamento on assegnamento.codice_sp = pacco.codice_sp
	 JOIN veicolo ON veicolo.codice_v = assegnamento.codice_v
WHERE pacco.codice_sp = assegnamento.codice_sp;


CREATE VIEW spedizioni_accettate_24H (sp_accettate) AS
SELECT count(*)
FROM fase
where nome = "confermata" AND data_ora > (NOW() - interval 1 day);


CREATE VIEW spedizioni_consegnate_24H (sp_consegnate, entrate_totali) AS
SELECT count(*), sum(costo_effettivo)
FROM fase JOIN costo_spedizione on codice_sp = codice_spedizione
where nome = "consegnato" AND data_ora > (NOW() - interval 1 day);

-- FROM pacco JOIN fase ON pacco.codice_sp = fase.codice_sp 
--	 JOIN assegnamento ON assegnamento.codice_sp = pacco.codice_sp
--	 JOIN veicolo ON veicolo.codice_v = assegnamento.codice_v
-- WHERE fase.nome = "in transito" and fase.data_ora = (SELECT max(data_ora)
--													FROM fase as fase2
--													WHERE fase.codice_sp = fase2.codice_sp);


CREATE VIEW coordinata_ritiro_pacco_cliente (cf_cl, latitudine_cl, longitudine_cl) AS
SELECT cf, latitudine_cgr, longitudine_cgr
FROM cliente JOIN coordinate_cliente as cc ON cc.cf_cliente = cf
WHERE flag = TRUE;


-- procedures

-- DELIMITER //
-- CREATE PROCEDURE elimina_spedizione (IN codice_sp INT)
--	BEGIN
--	DELETE FROM spedizione WHERE codice_spedizione = codice_sp
--	END //
-- DELIMITER ;


DELIMITER //
CREATE PROCEDURE traccia_pacco (IN codice INT)
BEGIN
	SELECT codice_sp, nome, data_ora
	FROM fase
	WHERE codice = codice_sp;
END //
DELIMITER ;



-- events


SET GLOBAL EVENT_SCHEDULER = ON;

CREATE EVENT report
ON SCHEDULE EVERY 1 day
ON COMPLETION PRESERVE
DO 
	SELECT sp_accettate, sp_consegnate, entrate_totali
	FROM spedizioni_accettate_24H, spedizioni_consegnate_24H;




-- da eliminare

insert into categoria 
values ("media", 40, 100, 1000);

insert into categoria
values ("piccola", 10, 0, 100);  

insert into cliente
values ("abcguri294ktuehv", "federico", "prova", "1999-02-26", "via ciao", "roma", 00012, "roma", "via ciao", "roma", 00012, "roma");

insert into carta_di_credito
values (5333123187465423, "federico", "prova", "2022-12-12", 432, "abcguri294ktuehv");

insert into coordinate_geo_rec_pacchi
values (43,13);

insert into coordinate_cliente
values ("abcguri294ktuehv", 43, 13, TRUE);

insert into veicolo
values (1, "aa111aa", 1000, "furgone", 41, 41),
(2, "aa222aa", 10000, "autoarticolato", 89, 23),
(3, "aa333aa", 1000, "furgone", 89, 23),
(4, "aa444aa", 10000, "autoarticolato", 89, 23),
(5, "aa555aa", 1000, "furgone", 89, 23),
(6, "aa666aa", 10000, "autoarticolato", 89, 23),
(7, "aa777aa", 1000, "furgone", 89, 23),
(8, "aa888aa", 10000, "autoarticolato", 89, 23),
(9, "aa999aa", 1000, "furgone", 89, 23),
(10, "aa000bb", 10000, "autoarticolato", 89, 23),
(11, "aa111bb", 1000, "furgone", 89, 23),
(12, "aa222bb", 10000, "autoarticolato", 89, 23),
(13, "aa333bb", 1000, "furgone", 89, 23),
(14, "aa444bb", 10000, "autoarticolato", 89, 23),
(15, "aa555bb", 1000, "furgone", 89, 23),
(16, "aa666bb", 10000, "autoarticolato", 89, 23),
(17, "aa777bb", 1000, "furgone", 89, 23),
(18, "aa888bb", 10000, "autoarticolato", 89, 23),
(19, "aa999bb", 1000, "furgone", 89, 23),
(20, "aa000cc", 10000, "autoarticolato", 89, 23),
(21, "aa111cc", 1000, "furgone", 89, 23),
(22, "aa222cc", 10000, "autoarticolato", 89, 23);


insert into possiede
values (1,1),
(1,2),
(2,3),
(2,4),
(3,5),
(3,6),
(4,7),
(4,8),
(5,9),
(5,10),
(6,11),
(6,12),
(7,13),
(7,14),
(8,15),
(8,16),
(9,17),
(9,18),
(10,19),
(10,20),
(11,21),
(11,22);




INSERT INTO centro_operativo
VALUES (1, "via di panico 7", "roma", 00186, "roma", 069812846, 41.899992, 12.467946, "russo", "centroroma@gmail.com", "centro prossimità"),
(2, "via paolo orsi 15", "roma", 00178, "roma", 067323182, 41.821876, 12.584744, "verdi", "centroroma2@gmail.com", "centro prossimità"),
(3, "via camilla ravera 5", "roma", 00135, "roma", 068473192, 41.958950, 12.395798, "rossi", "centroroma3@gmail.com", "centro prossimità"),
(4, "via edimburgo 83", "roma", 00144, "roma", 06783256, 41.819247, 12.453754, "bianchi", "centroroma4@gmail.com", "centro smistamento nazionale"),
(5, "via pal grande 10", "fiumicino", 00054, "roma", 06532324, 41.771333, 12.264104, "romano", "centrofiumicino@gmail.com", "centro smistamento internazionale"),
(6, "via dei serragli 32", "firenze", 50125, "firenze", 05432654, 43.767032, 11.245384, "ricci", "centrofirenze@gmail.com", "centro prossimità"),
(7, "via amati 7", "pistoia", 51100, "pistoia", 05636734, 43.931099, 10.918457, "gatti", "centropistoia@gmail.com", "centro prossimità"),
(8, "via del pino 15", "firenze", 50137, "firenze", 05358796, 43.779575, 11.295022, "testa", "centrofirenze2@gmail.com", "centro smistamento nazionale"),
(9, "rue de rungis 14", "parigi", 75013, "parigi", 57389354, 48.821856, 2.344542, "fontana", "centroparigi@gmail.com", "centro prossimità"),
(10, "passage panel 8", "parigi", 75018, "parigi", 324235112, 48.896086, 2.342369, "ferrari", "centroparigi2@gmail.com", "centro smistamento nazionale"),
(11, "rue delagarde 41", "montfermeil", 93370, "parigi", 32434234, 48.902070, 2.568547, "costa", "centromontfermeil@gmail.com", "centro smistamento internazionale");


SET autocommit = OFF;

START TRANSACTION;
insert into destinatario
values (43, 13, "ciao", "ciao", "francia");

insert into spedizione (codice_spedizione, cf_cliente, latitudine_des, longitudine_des)
values (1, "abcguri294ktuehv", 43, 13);

insert into pacco(codice_sp, peso, lunghezza, larghezza, profondità)
values (1, 23, 10, 5, 5);

COMMIT;

set autocommit = ON;


-- insert into pacco
-- values (1, 23, 10, 10, 5, NULL);







