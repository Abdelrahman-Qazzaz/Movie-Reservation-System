PGDMP         $    	            |            Movie_Reservation_System    15.4    15.4 D    M           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            N           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            O           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            P           1262    35265    Movie_Reservation_System    DATABASE     |   CREATE DATABASE "Movie_Reservation_System" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';
 *   DROP DATABASE "Movie_Reservation_System";
                postgres    false            �            1259    35275    movie_show_days    TABLE     �   CREATE TABLE public.movie_show_days (
    id integer NOT NULL,
    movie_id integer NOT NULL,
    date date NOT NULL,
    has_instances_with_seats_left boolean,
    recursion_flag boolean
);
 #   DROP TABLE public.movie_show_days;
       public         heap    postgres    false            �            1255    35366 9   filter_show_days_by_the_times_of_their_instances_gt(text)    FUNCTION       CREATE FUNCTION public.filter_show_days_by_the_times_of_their_instances_gt(desired_time text) RETURNS SETOF public.movie_show_days
    LANGUAGE plpgsql
    AS $$BEGIN
    RETURN QUERY
    SELECT msd.*
    FROM movie_show_days msd
    WHERE EXISTS (
        SELECT 1
        FROM movie_show_days_instances msdi
        WHERE msdi.movie_show_day_id = msd.id  -- Assuming there's a foreign key relationship
          AND msdi.time > filter_show_days_by_the_times_of_their_instances_gt.desired_time::TIME
    );
END;
$$;
 ]   DROP FUNCTION public.filter_show_days_by_the_times_of_their_instances_gt(desired_time text);
       public          postgres    false    214            �            1255    35367 9   filter_show_days_by_the_times_of_their_instances_lt(text)    FUNCTION     �  CREATE FUNCTION public.filter_show_days_by_the_times_of_their_instances_lt(desired_time text) RETURNS SETOF public.movie_show_days
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT msd.*
    FROM movie_show_days msd
    WHERE EXISTS (
        SELECT 1
        FROM movie_show_days_instances msdi
        WHERE msdi.movie_show_day_id = msd.id  
          AND msdi.time < filter_show_days_by_the_times_of_their_instances_lt.desired_time::TIME
    );
END;
$$;
 ]   DROP FUNCTION public.filter_show_days_by_the_times_of_their_instances_lt(desired_time text);
       public          postgres    false    214            �            1255    35268 #   get_movie_show_day_details(integer)    FUNCTION     �  CREATE FUNCTION public.get_movie_show_day_details(movie_show_day_id integer) RETURNS TABLE(msd_date date, msdi_time time without time zone, m_title text, m_description text, m_release_date date, m_available_in_languages text[], m_popularity double precision, m_votecount integer, m_voteaverage double precision, m_adult boolean, m_poster text, msd_has_instances_with_seats_left boolean, msdi_has_seats_left boolean, msdit_id integer, msdit_seat_position character, msdit_reserved_by_user_id integer)
    LANGUAGE plpgsql
    AS $_$
BEGIN
  RETURN QUERY
  SELECT
    msd.date AS msd_date,
    msdi.time AS msdi_time,
    m.title AS m_title,
    m.description AS m_description,
    m.release_date AS m_release_date,
    m.languages AS m_available_in_languages,
    m.popularity AS m_popularity,
    m.votecount AS m_votecount,
    m.voteaverage AS m_voteaverage,
    m.adult AS m_adult,
    m.image_url AS m_poster,
    msd.has_instances_with_seats_left AS msd_has_instances_with_seats_left,
    msdi.has_seats_left AS msdi_has_seats_left, 
    msdit.id AS msdit_id,
    msdit.seat_position AS msdit_seat_position,
    msdit.reserved_by_user_id AS msdit_reserved_by_user_id
  FROM movie_show_days AS msd
  JOIN movies AS m ON m.id = msd.movie_id
  JOIN movie_show_days_instances AS msdi ON msd.id = msdi.movie_show_day_id
  JOIN movie_show_days_instances_tickets AS msdit ON msdi.id = msdit.movie_show_day_instance_id
  WHERE msd.id = $1;
END;
$_$;
 L   DROP FUNCTION public.get_movie_show_day_details(movie_show_day_id integer);
       public          postgres    false            �            1255    35269    get_ticket_details(integer)    FUNCTION     �  CREATE FUNCTION public.get_ticket_details(target_ticket_id integer) RETURNS TABLE(ticket_id integer, seat_position character, ticket_reserved_by_user_id integer, show_date date, show_start_time time without time zone, movie_title text, movie_poster text, movie_adult boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    msdit.id AS ticket_id, 
    msdit.seat_position, 
    msdit.reserved_by_user_id AS ticket_reserved_by_user_id, 
    msd.date AS show_date, 
    msdi.time AS show_start_time, 
    m.title AS movie_title, 
    m.image_url AS movie_poster, 
    m.adult AS movie_adult
  FROM movie_show_days_instances_tickets AS msdit
  JOIN movie_show_days_instances AS msdi ON msdit.movie_show_day_instance_id = msdi.id
  JOIN movie_show_days AS msd ON msdi.movie_show_day_id = msd.id
  JOIN movies AS m ON msd.movie_id = m.id
  WHERE msdit.id = target_ticket_id;
END;
$$;
 C   DROP FUNCTION public.get_ticket_details(target_ticket_id integer);
       public          postgres    false            �            1255    35270    log_transaction(text, jsonb)    FUNCTION     �  CREATE FUNCTION public.log_transaction(customer_email text, ticket_details jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_id INTEGER;
BEGIN

    SELECT id INTO user_id 
    FROM users 
    WHERE email = customer_email;

    -- This will cause a trigger fuction to execute.
INSERT INTO transactions (
        user_id,
        purchased_ticket_id,
        purchased_item_amount_total,
        purchased_item_currency
    )
    VALUES (
        user_id,
        (ticket_details->>'ticket_id')::INTEGER, 
        (ticket_details->>'amount_total')::NUMERIC,  
        ticket_details->>'currency'
    );
    RETURN;
END;
$$;
 Q   DROP FUNCTION public.log_transaction(customer_email text, ticket_details jsonb);
       public          postgres    false            �            1255    35271 5   node_cron_remove_outdated_movie_show_days_cascading()    FUNCTION     l  CREATE FUNCTION public.node_cron_remove_outdated_movie_show_days_cascading() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    target_show_day movie_show_days%ROWTYPE;  
    target_show_day_instance movie_show_days_instances%ROWTYPE; 
    num_of_instances_for_show_day INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM movie_show_days WHERE date <= CURRENT_DATE) THEN
        FOR target_show_day IN
            SELECT * FROM movie_show_days WHERE date <= CURRENT_DATE
        LOOP
            IF EXISTS (SELECT 1 FROM movie_show_days_instances WHERE movie_show_day_id = target_show_day.id) THEN
                FOR target_show_day_instance IN
                    SELECT * FROM movie_show_days_instances WHERE movie_show_day_id = target_show_day.id
                LOOP
                    IF target_show_day_instance.time <= CURRENT_TIME THEN 
                        DELETE FROM movie_show_days_instances WHERE id = target_show_day_instance.id;
                    END IF;
                END LOOP;
            END IF;
            
            SELECT COUNT(*) INTO num_of_instances_for_show_day 
            FROM movie_show_days_instances 
            WHERE movie_show_day_id = target_show_day.id;

            IF num_of_instances_for_show_day = 0 THEN
                DELETE FROM movie_show_days WHERE id = target_show_day.id;
            END IF;
        END LOOP;
    END IF;
END;
$$;
 L   DROP FUNCTION public.node_cron_remove_outdated_movie_show_days_cascading();
       public          postgres    false            �            1255    35369 7   run_after_insert_on_movie_show_days_instances_tickets()    FUNCTION     �   CREATE FUNCTION public.run_after_insert_on_movie_show_days_instances_tickets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE movie_show_days_instances SET has_seats_left = TRUE 
	WHERE id = OLD.movie_show_day_instance_id;
END;
$$;
 N   DROP FUNCTION public.run_after_insert_on_movie_show_days_instances_tickets();
       public          postgres    false            �            1255    35272 "   run_after_insert_on_transactions()    FUNCTION        CREATE FUNCTION public.run_after_insert_on_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE movie_show_days_instances_tickets 
	SET reserved_by_user_id = NEW.user_id
	WHERE id = NEW.purchased_ticket_id;
    RETURN NULL;
END;
$$;
 9   DROP FUNCTION public.run_after_insert_on_transactions();
       public          postgres    false            �            1255    35273 /   run_after_update_on_movie_show_days_instances()    FUNCTION     �  CREATE FUNCTION public.run_after_update_on_movie_show_days_instances() RETURNS trigger
    LANGUAGE plpgsql
    AS $$--the trigger
--on_update_on_movie_show_days_instances
--is defined on the table
--movie_show_days_instances

DECLARE
  num_of_instances_left INTEGER;

BEGIN

  SELECT COUNT(*) 
  INTO num_of_instances_left
  FROM movie_show_days_instances
  WHERE movie_show_day_id = NEW.movie_show_day_id AND has_seats_left IS NOT FALSE;

  IF num_of_instances_left = 0 THEN
    UPDATE movie_show_days
    SET has_instances_with_seats_left = FALSE
    WHERE id = OLD.movie_show_day_id; 
	ELSE
	    UPDATE movie_show_days
    SET has_instances_with_seats_left = TRUE
    WHERE id = OLD.movie_show_day_id; 
  END IF;
  RETURN NULL;
END;
$$;
 F   DROP FUNCTION public.run_after_update_on_movie_show_days_instances();
       public          postgres    false            �            1255    35274 7   run_after_update_on_movie_show_days_instances_tickets()    FUNCTION     4  CREATE FUNCTION public.run_after_update_on_movie_show_days_instances_tickets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$--the trigger
--on_update_on_movie_show_days_instances_tickets
--is defined on the table
--movie_show_days_instances_tickets

DECLARE
  num_of_free_seats_left INTEGER;


BEGIN 


  SELECT COUNT(*) 
  INTO num_of_free_seats_left
  FROM movie_show_days_instances_tickets
  WHERE movie_show_day_instance_id = OLD.movie_show_day_instance_id 
  AND 
  NEW.reserved_by_user_id IS NULL;



  IF num_of_free_seats_left = 0 THEN
    UPDATE movie_show_days_instances
    SET has_seats_left = FALSE
    WHERE id = OLD.movie_show_day_instance_id; 
	ELSE
	    UPDATE movie_show_days_instances
    SET has_seats_left = TRUE
    WHERE id = OLD.movie_show_day_instance_id;
  END IF;

  RETURN NULL;
  
END;
$$;
 N   DROP FUNCTION public.run_after_update_on_movie_show_days_instances_tickets();
       public          postgres    false            �            1259    35278    movie_show_days_instances    TABLE     �   CREATE TABLE public.movie_show_days_instances (
    id integer NOT NULL,
    movie_show_day_id integer NOT NULL,
    "time" time without time zone NOT NULL,
    has_seats_left boolean NOT NULL
);
 -   DROP TABLE public.movie_show_days_instances;
       public         heap    postgres    false            �            1259    35281 !   movie_show_days_instances_tickets    TABLE     �   CREATE TABLE public.movie_show_days_instances_tickets (
    id integer NOT NULL,
    seat_position character(2) NOT NULL,
    movie_show_day_instance_id integer NOT NULL,
    reserved_by_user_id integer
);
 5   DROP TABLE public.movie_show_days_instances_tickets;
       public         heap    postgres    false            �            1259    35284    movies    TABLE     ]  CREATE TABLE public.movies (
    id integer NOT NULL,
    title text NOT NULL,
    release_date date NOT NULL,
    languages text[] NOT NULL,
    description text NOT NULL,
    popularity double precision NOT NULL,
    voteaverage double precision NOT NULL,
    votecount integer NOT NULL,
    adult boolean NOT NULL,
    image_url text NOT NULL
);
    DROP TABLE public.movies;
       public         heap    postgres    false            �            1259    35289    movies_id_seq    SEQUENCE     �   CREATE SEQUENCE public.movies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.movies_id_seq;
       public          postgres    false    217            Q           0    0    movies_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.movies_id_seq OWNED BY public.movies.id;
          public          postgres    false    218            �            1259    35290    show_days_instances_id_seq    SEQUENCE     �   CREATE SEQUENCE public.show_days_instances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.show_days_instances_id_seq;
       public          postgres    false    215            R           0    0    show_days_instances_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.show_days_instances_id_seq OWNED BY public.movie_show_days_instances.id;
          public          postgres    false    219            �            1259    35291 "   show_days_instances_tickets_id_seq    SEQUENCE     �   CREATE SEQUENCE public.show_days_instances_tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.show_days_instances_tickets_id_seq;
       public          postgres    false    216            S           0    0 "   show_days_instances_tickets_id_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE public.show_days_instances_tickets_id_seq OWNED BY public.movie_show_days_instances_tickets.id;
          public          postgres    false    220            �            1259    35292    showtimes_id_seq    SEQUENCE     �   CREATE SEQUENCE public.showtimes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.showtimes_id_seq;
       public          postgres    false    214            T           0    0    showtimes_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.showtimes_id_seq OWNED BY public.movie_show_days.id;
          public          postgres    false    221            �            1259    35293    transactions    TABLE     �   CREATE TABLE public.transactions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    purchased_ticket_id integer NOT NULL,
    purchased_item_amount_total double precision NOT NULL,
    purchased_item_currency character varying(10) NOT NULL
);
     DROP TABLE public.transactions;
       public         heap    postgres    false            �            1259    35296    transactions_int_seq    SEQUENCE     �   CREATE SEQUENCE public.transactions_int_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.transactions_int_seq;
       public          postgres    false    222            U           0    0    transactions_int_seq    SEQUENCE OWNED BY     L   ALTER SEQUENCE public.transactions_int_seq OWNED BY public.transactions.id;
          public          postgres    false    223            �            1259    35297    users    TABLE     �   CREATE TABLE public.users (
    id integer NOT NULL,
    full_name text NOT NULL,
    phone_number text NOT NULL,
    email text NOT NULL,
    password text NOT NULL
);
    DROP TABLE public.users;
       public         heap    postgres    false            �            1259    35302    users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public          postgres    false    224            V           0    0    users_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
          public          postgres    false    225            �           2604    35359    movie_show_days id    DEFAULT     r   ALTER TABLE ONLY public.movie_show_days ALTER COLUMN id SET DEFAULT nextval('public.showtimes_id_seq'::regclass);
 A   ALTER TABLE public.movie_show_days ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    221    214            �           2604    35360    movie_show_days_instances id    DEFAULT     �   ALTER TABLE ONLY public.movie_show_days_instances ALTER COLUMN id SET DEFAULT nextval('public.show_days_instances_id_seq'::regclass);
 K   ALTER TABLE public.movie_show_days_instances ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    219    215            �           2604    35361 $   movie_show_days_instances_tickets id    DEFAULT     �   ALTER TABLE ONLY public.movie_show_days_instances_tickets ALTER COLUMN id SET DEFAULT nextval('public.show_days_instances_tickets_id_seq'::regclass);
 S   ALTER TABLE public.movie_show_days_instances_tickets ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    216            �           2604    35362 	   movies id    DEFAULT     f   ALTER TABLE ONLY public.movies ALTER COLUMN id SET DEFAULT nextval('public.movies_id_seq'::regclass);
 8   ALTER TABLE public.movies ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    217            �           2604    35363    transactions id    DEFAULT     s   ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_int_seq'::regclass);
 >   ALTER TABLE public.transactions ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    223    222            �           2604    35364    users id    DEFAULT     d   ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 7   ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    225    224            ?          0    35275    movie_show_days 
   TABLE DATA           l   COPY public.movie_show_days (id, movie_id, date, has_instances_with_seats_left, recursion_flag) FROM stdin;
    public          postgres    false    214   �q       @          0    35278    movie_show_days_instances 
   TABLE DATA           b   COPY public.movie_show_days_instances (id, movie_show_day_id, "time", has_seats_left) FROM stdin;
    public          postgres    false    215   s       A          0    35281 !   movie_show_days_instances_tickets 
   TABLE DATA              COPY public.movie_show_days_instances_tickets (id, seat_position, movie_show_day_instance_id, reserved_by_user_id) FROM stdin;
    public          postgres    false    216   �t       B          0    35284    movies 
   TABLE DATA           �   COPY public.movies (id, title, release_date, languages, description, popularity, voteaverage, votecount, adult, image_url) FROM stdin;
    public          postgres    false    217   ��       G          0    35293    transactions 
   TABLE DATA           ~   COPY public.transactions (id, user_id, purchased_ticket_id, purchased_item_amount_total, purchased_item_currency) FROM stdin;
    public          postgres    false    222   �@      I          0    35297    users 
   TABLE DATA           M   COPY public.users (id, full_name, phone_number, email, password) FROM stdin;
    public          postgres    false    224   A      W           0    0    movies_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.movies_id_seq', 999, true);
          public          postgres    false    218            X           0    0    show_days_instances_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.show_days_instances_id_seq', 153, true);
          public          postgres    false    219            Y           0    0 "   show_days_instances_tickets_id_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public.show_days_instances_tickets_id_seq', 5339, true);
          public          postgres    false    220            Z           0    0    showtimes_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.showtimes_id_seq', 111, true);
          public          postgres    false    221            [           0    0    transactions_int_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.transactions_int_seq', 28, true);
          public          postgres    false    223            \           0    0    users_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.users_id_seq', 4, true);
          public          postgres    false    225            �           2606    35310    movies movies_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.movies DROP CONSTRAINT movies_pkey;
       public            postgres    false    217            �           2606    35312 2   movie_show_days_instances show_days_instances_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.movie_show_days_instances
    ADD CONSTRAINT show_days_instances_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.movie_show_days_instances DROP CONSTRAINT show_days_instances_pkey;
       public            postgres    false    215            �           2606    35314 B   movie_show_days_instances_tickets show_days_instances_tickets_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.movie_show_days_instances_tickets
    ADD CONSTRAINT show_days_instances_tickets_pkey PRIMARY KEY (id);
 l   ALTER TABLE ONLY public.movie_show_days_instances_tickets DROP CONSTRAINT show_days_instances_tickets_pkey;
       public            postgres    false    216            �           2606    35316    movie_show_days showtimes_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.movie_show_days
    ADD CONSTRAINT showtimes_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.movie_show_days DROP CONSTRAINT showtimes_pkey;
       public            postgres    false    214            �           2606    35318    transactions transactions_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_pkey;
       public            postgres    false    222            �           2606    35320    users unique_email_constraint 
   CONSTRAINT     Y   ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_email_constraint UNIQUE (email);
 G   ALTER TABLE ONLY public.users DROP CONSTRAINT unique_email_constraint;
       public            postgres    false    224            �           2606    35322    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    224            �           1259    35368    movie_title    INDEX     ?   CREATE INDEX movie_title ON public.movies USING btree (title);
    DROP INDEX public.movie_title;
       public            postgres    false    217            �           2620    35370 P   movie_show_days_instances_tickets on_insert_on_movie_show_days_instances_tickets    TRIGGER     �   CREATE TRIGGER on_insert_on_movie_show_days_instances_tickets AFTER INSERT ON public.movie_show_days_instances_tickets FOR EACH ROW EXECUTE FUNCTION public.run_after_insert_on_movie_show_days_instances_tickets();
 i   DROP TRIGGER on_insert_on_movie_show_days_instances_tickets ON public.movie_show_days_instances_tickets;
       public          postgres    false    227    216            �           2620    35323 &   transactions on_insert_on_transactions    TRIGGER     �   CREATE TRIGGER on_insert_on_transactions AFTER INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.run_after_insert_on_transactions();
 ?   DROP TRIGGER on_insert_on_transactions ON public.transactions;
       public          postgres    false    246    222            �           2620    35324 @   movie_show_days_instances on_update_on_movie_show_days_instances    TRIGGER     �   CREATE TRIGGER on_update_on_movie_show_days_instances AFTER UPDATE ON public.movie_show_days_instances FOR EACH ROW EXECUTE FUNCTION public.run_after_update_on_movie_show_days_instances();
 Y   DROP TRIGGER on_update_on_movie_show_days_instances ON public.movie_show_days_instances;
       public          postgres    false    215    226            �           2620    35325 P   movie_show_days_instances_tickets on_update_on_movie_show_days_instances_tickets    TRIGGER     �   CREATE TRIGGER on_update_on_movie_show_days_instances_tickets AFTER UPDATE ON public.movie_show_days_instances_tickets FOR EACH ROW EXECUTE FUNCTION public.run_after_update_on_movie_show_days_instances_tickets();
 i   DROP TRIGGER on_update_on_movie_show_days_instances_tickets ON public.movie_show_days_instances_tickets;
       public          postgres    false    216    228            �           2606    35326 >   movie_show_days_instances show_days_instances_show_day_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.movie_show_days_instances
    ADD CONSTRAINT show_days_instances_show_day_id_fkey FOREIGN KEY (movie_show_day_id) REFERENCES public.movie_show_days(id);
 h   ALTER TABLE ONLY public.movie_show_days_instances DROP CONSTRAINT show_days_instances_show_day_id_fkey;
       public          postgres    false    215    3481    214            �           2606    35331 V   movie_show_days_instances_tickets show_days_instances_tickets_reserved_by_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.movie_show_days_instances_tickets
    ADD CONSTRAINT show_days_instances_tickets_reserved_by_user_id_fkey FOREIGN KEY (reserved_by_user_id) REFERENCES public.users(id);
 �   ALTER TABLE ONLY public.movie_show_days_instances_tickets DROP CONSTRAINT show_days_instances_tickets_reserved_by_user_id_fkey;
       public          postgres    false    224    216    3494            �           2606    35336 W   movie_show_days_instances_tickets show_days_instances_tickets_show_day_instance_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.movie_show_days_instances_tickets
    ADD CONSTRAINT show_days_instances_tickets_show_day_instance_id_fkey FOREIGN KEY (movie_show_day_instance_id) REFERENCES public.movie_show_days_instances(id);
 �   ALTER TABLE ONLY public.movie_show_days_instances_tickets DROP CONSTRAINT show_days_instances_tickets_show_day_instance_id_fkey;
       public          postgres    false    215    216    3483            �           2606    35341 '   movie_show_days showtimes_movie_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.movie_show_days
    ADD CONSTRAINT showtimes_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(id);
 Q   ALTER TABLE ONLY public.movie_show_days DROP CONSTRAINT showtimes_movie_id_fkey;
       public          postgres    false    217    3488    214            �           2606    35346 2   transactions transactions_purchased_ticket_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_purchased_ticket_id_fkey FOREIGN KEY (purchased_ticket_id) REFERENCES public.movie_show_days_instances_tickets(id);
 \   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_purchased_ticket_id_fkey;
       public          postgres    false    216    222    3485            �           2606    35351 &   transactions transactions_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
 P   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_user_id_fkey;
       public          postgres    false    3494    222    224            ?   C  x�U��m1���]\H�~�%:A����.'�Z Ox$%9L���`�x��%�)����N�E}�ES(�M��
��67�X����Up���8��� {<����q5�;1�E/Ȝ��N�2Y9�5+o?�̘�3^�ry�3�N�X5���[ouN�V��ӻ
�C��;O��#q<�5�.��1���0��w��`fǛva�E�=�"M`k��bm¹nI1�"M��$;���;
����:~��#a�o9��B���Nlcɧ�~�0��	+�y>�v�ڽ���.�,�3��Ķx��X�C*�Ͼ�ﳓ>1�g�/_=����z�~�M�      @   �  x�M�I�1�5u���g�O����@Vj�B�����D�T������dҿ�dB< � ����LI0� ��R��Cf�[tl��  ��l`�8�H��R�"�$�3� �t�8V�̄��tw-�Zv$=(�$@����4����@/P���T?
Fµ�)笖��3��|aS�V��`�� 9	(N8�z_����$��>�-�RF�T2 ��$�~6>R"�Fk1�Z�������ȸ䤬W�ɹ���<ϻbR��$�� ��e��%NqE����v{�]� r˦(���""��CD�zIdv��ޮ
���Xʹ�D�g����K&�;V�W�+%2o�<ٳ���~�
N�O��,Z�&���S"�My>����=��:���2i�S{ݵR���?Rrh���O|3�_�3ū�]�B��XJv#������Z�%      A      x�M�Kv-=o����SKy�l~Gw5j5�q�7"Ȏ������C$	�Ա��{{]���������?��V�|�������o�����?߯�N����������������?���������{��������{���������{ޯ�������{�����^��ﵾ��{�|���׻�u���{�����{]�w���~���^��ݿ�~{������ݿ�^_��������ׇ�}�>�{�����{_����~}�����ÿ�y{}��>��ÿ�Y_��������}�ק�s�>�{������\�O���~}��>��ӿwy{{}����|����l��%�__kp����|}����:���u��+,o��D�,��D����D�l��D���D���D����D�\��D�ܯ�D�<��D�����������~���~���~�z�~�z�~�z�~�z�~���~����I���I���M���M���M���M�YIaWe᮴ <���V�AX*3k�a�� �����pVz���]	Bx*C��R��T��J�VYB�+MG�	�D!\�)��R��T� -ٽ'����AKw��D��{"h�=����Z��H-�}$���>AK{��彏D��G"h��H�?}$���>AK~���e��D���g"h��3���Z�L-~&��?AK����e�OG��i}-��|V6���U�D�+�OeВ�WbiY�+�����XZ^�J,-1~%�������Aˍ߉�%��Dвc���[v�GXj�k-a��#�x���p���Z<�]�Gxj��%���%���%���%���%���%���%���%���%���Aˎe��Dв�{"h��=����Zv|O-;�'���AˎeǏDв�G"h��#����Zv�H-;~$��?Aˎ��eǏDв�G"h��3����Zv�L-;~&��?Aˎ���e��Dв�g"h��3����Zv�J-;~%���Aˎ_��eǯDв�W"h��+����Zv�J-;~%���Aˎ߉����k�a�U"�J��V�p�*�Z%�]�Dxj����*�Z%�Z�D�j�{��U"��J��V�p�*�Z%�e����Aˎe��Dв�{"h��=����ZN|O-'�'���Aˉ�Aˉ���ďD�r�G"h9�#����ZN�H-'~$��?��r��,�J��V���*�Z%�Q�D8k�W��U"<�J@ˉ����Aˉ_���įD�r�W"h9�+,�.�nI`�$�[+�%�ݒ�nI`�$�[�-	�vK�%����-	�vK�%�ݒ�nI`�$�[�-	���nI`�$�[�-	�vK�%�ݒ�nI`�vK�%�ݒ�nI`�$�[�-	�vK�%p�[�-	�vK�%�ݒ�I`�$��o�O�='��R�F����
[���7*�oT8�ߨpտQ���S�FAω��������������������������������D�sb"�91����ZN|O-'�'���Aˉ���D�r�{"�91������`���Z�F����
{���7*��oT��ߨp׿Q�����D�r�g"h9�3����ZN�L-'~&��?Aˉ����įD�r�W"h9�+����ZN�J-'~%���Aˉ_���įD�r�W"h9�;����ZN�N-'~'���Aˉ߉����D�r�w"h9�;����ZN�I-'�$��Aˉ?���ğD�r�O"h9�'����ZN�I-'�$��Aˉ������D�r�o"h9�7����ZN�M-'�&��A��_������T�d�K%!a�$$l������pT�JB�UIH�+		O%!Ћ����A�'&��OL}���>1�}b"�5�DЋ���WA/#&��OL}���>1�}b"���D�����WA/'&�^OL����>1�}b"���D������A�'&�^WL���ze����K%!a�$$l������pT�JB�UIH�+		O%!�+����A�'&��OL}���>1����ze1��b"��D�+���WAˉ߉����D�r�w"h9�;����ze1��?h��
�?���?0j`������Q���F����?���?0j`������Q���F����?���?0j`������Q���F����?���?0j`������Q���F����?���?0j`������Q���F����?���?0j`������Q���F����?���?0j`������Q���F����? �[����?0j`������Q���F���K����?0j`������Q��z�&���Aˉ���ĿD�r�_"h9�/��s�_���R�pTJ�Ji�U)M�+�	O�4�s�,�҄�R��UJ�Ji�Q)M8+�	W�4ᮔ&<��@ω����D�sb"�g�D��Ή���Aˉ���D�sb"�91���zNL='&�~vN����9����ZN�H='&��Aω����D�sb"�g�D��Ή���Aˉ������D�sb"�91���zNL='&���Aˉ_���įD�r�W"h9�+�����/���qW����Q���F���/�_0��`T�����T����Q���F���/�_0��`T����ު�`T����Q���F���/�_0��`TAX��`T����Q���F���/�_0��`TAX��`T����Q���F���/�_0��`TAت�`T����Q���F���/�_0��`TAث�`,����T[}���>��Q�j�O�pէZ��S-<��-'�$��Aˉ?���ˤY�L_&�/���I��$�eҴ
_&�/���I��$�e�2	|��L_&�/�fd�2	|��L_&�/���I��$�e�2	|�4�×I��$�e�2	|��L_&�/���I�ˤy �L_&�/���I��$�e�2	|��L_&M!�e�2	|��L_&�/���I��$�e�Z��}z�,,����V���
�Z��Q+X8kW�`�,<��5q�V+XXjk�`a�,쵂��V�p�
��lwm���6۠O�$�>��ZN�I}*'���DЧrAˉ��`�Zڽ���UK���UK3��fT-ͨZ�Q�4�jiF�Ҍ��UK���UK3��fT-ͨZ�Q�4�jiF�Ҍ��UKΪ�UK3��fT-ͨZ�Q�4�jiF�Ҍ��UK���UK3��fT-ͨZ�Q�4�jiF�Ҍ��UKUK3��fT-ͨZ�Q�4�jiF�Ҍ��UK���UK3��fT-ͨZ�qԿ���/^��_�p׿x�����R�ⅵ��[����/�/^8�_�pտx���S��A��I}'�Y�D�gqA��I-'�'���Aˉ���D�gqA��I}'�Y�D�gqA��I-'~$��?Aˉ���ďD�gqA��I}'�Y�D�gqA��I-'~&��?Aˉ������D�gqA��I}'�Y�D�gqA��I-'~%���Aˉ_���įD�gqA��I}'�Y�D�gqA��I-'~'���Aˉ߉����D�gqA��I-'~'���Aˉ߉��X�/=�QP8k
W-@�(<� A�;��RPXk
[-@a�(� ���p��Z��S��s"�}�D��Ή���A�$��cI�ǒ�,N"�}�D��Ή���A�;'��wN��z�%�K"�=�D�gqA�;'��wv�[o<�CK-Ak�5hm���V�u�2��Z��UѺk%ZO-E���G,�=b�M�K�B�Xz�e��{.#��t��,�5b��K�E�Xz3z�һ�#�ގ��~�7_F,��2bYkP辤��jT(�Y!k�a������j^(����&���jf(��������Ɔ���jp(�ɡ�F����jx(�顨Ƈ���� �j�(���f��"�j�(�1��戢    $�j��:k�(�Y������&�j�(�y�����(�j�(��"몡�����+�j�(����&��-�j�(��&���F�����j;�)�ư��Îj;�I�F���>�RoߌXz�f��8#�����Έ��pF,-���XZ����6Έ��qK�6�-u���:CZ["��N��Q�H�s�u�AҺ�$iQC��B٢�lQF��#[�-*��d�Z�E1٢�,���-��e���EI٢�lQT��*[��-���Fa٢�lQZ��-[�-���e���E�٢�,픘-j�Ef�*�E�٢�lQh��4[��-j��A�٢�lQn��7[�-*�%g���E�٢�,���-���g�ʳE�٢�lQ|��>[��-���EڢmQ���A[�-��eh�:�E!ڢ-ݔ�-j��hk�Ld핉��2�uV&���D�]��z*I-���XZ������;biy�w�������K˻�#��wG,-���XZ��K,u!�鑖�|�Z���*�Y{e>��g�����2�uW泞�|R/�Xz=`��#�^����������:#�~Cg�ү�Xz�������WF,�40b鵁K/�X�M�K��3b�wuF,��Έ���K/�Xz�`�ҋ#�^%��2�������K;#�~kg�ү�Xz���b���WF,�\0b���K/�X��K��3b��wF,�ψ���K/�Xz�`��#�^9����������<#�~�g�ү�Xz����WF,��0b�5�K˻�#��w�G,-�~�XZ������=b�yw����ψ��ݟK˻?#��wF,-���XZ������3biy�g����ψ���K˻�#��wG,-���XZ������;biy�w�������K�k�#��wG,-���XZ������7biy�o����߈��ݿK˻#���ϛTm���R��ӲiT���ZQ�"�jFDՍ��U?"��DT	k��DT=���Qu%�jKD՗��1Ug"��DT�	k��DT݉��Q�'�jPDա��EU�"�&ET]
k�6ET}��Qu*�jUDի��YU�"�vET�
k��ET��ZQ�,�jZDյ��mU�"��ET���ET����Qu/�j_D5�0pT��Q�G5l�5�DpT#�Q�G5U/�Y�j�D�M���U?ź��UG%��JT=���*QuU�j�D�W���Ugź��Uo%��JTݕ��+Q�W�j�D�a���U��z��U�%�6KT}��-QuZ�j�D�k���U�E��E�P�[�j�D�q���U�%��KT]���.Q�]��/Qu^�j�D�{���U�%��KT���0Qu`��Z0Q�`�j�D5��R��D5���NT;Q��D5�c1N��NTc;Q��D5���NT�;Q��D5����`iT�;Q�D5��OT3<Q�D5��OTs<#�QM�D5��,OT�<QM�D5��<OT=QM�X�F5��POTS=Q��D5��`OT�=Q��D5�c1v�tOT�=Q��D5�ՄOT#>Q��D5�Ք�uטOTs>Q�D5�ըOT�>Q�D5�ոOT�>�S?QM�D5���OTC?QM�D5����$���]th�k�ߵ��Z�w-���]����~�b�k�ߕ�ߵ��Z�w-���]����~�b�k�ߵ��J��Z�w-���]����~�b�k�ߵ��Z�w%�w-���]����~�b�k�ߵ��Z�w-������]����~�b�k�ߵ��Z�w-���]I�]����~�b�k�ߵ��Z�w-���]�������~�b�k�ߵ��Zu.�kpQ݃����S�@�u�K�3�Xz�a���#�^g��:È��F,-���XZ������;b�u�K�3�Xz�a���#�^g��:È����W��?U:����T:��tT����Q����OG՟��?U:������?U:��tT����Q����OG՟��?U�Z�?U:��tT����Q����OG՟��?U�Z�?U:��tT����Q����OG՟��?U�ڪ?U:��tT����Q����OG՟��?U�ګ?U:��t�9��8X�,�� �s��9@:8X�,�� �s��9��`q�8X���s��9��`q�8X�,�� �s��9@�8X�,�� �s��9��`q�8X���s��9��`q�8X�,�� �s��9@z8X�,�� �s��9��`q�8X�P���uq�8X�,�� �s��9��`�<�Ü��<CT�Q�3D5��<CT�Q�3D5��<CT��Q�3D5��<CT�Q�3D5��<CT�Q�3X�3D5��<CT�Q�3D5��<CT�Q�3D5�`1��<CT�Q�3D5��<CT�Q�3D5��<��<CT�Q�3D5��<CT�Q�3D5��<CT��Q�3D5��<CT�Q�3D5��<CT�Q�3X�3D5��<CT�Q�3D5��<CT�Q�3D5�`1��<CT�Q�3D5��<CT�Q�3D5��<��<CT�Q�3D5��<CD����[��-j�5xts�!�oQ����[��-j�5x��Eޢ/q�!�oQ����[��-j�5x��Eޢ/q�!�oQ����[��-j�5x��Eޢ/q�!�oQ����[��-j�5x��Eޢ/q�!�oQ����[��-j�5x��Eޢ/q"�oQ���&DTW!���e��nCDu"��"��Օ���DD{�,먜e�����r�uWβ��Y�U3J�-ՌRT3JQ�(E5�ՌRT3JQ�(E5�Ռ�u׌RT3JQ�(E5�ՌRT3JQ�(E5�ՌRT3J�S3JQ�(E5�ՌRT3JQ�(E5�ՌRT3JQ�(I�2���P�(E5�ՌRT3JQ�(E5�ՌRT3JQ�(YK�(E5�ՌRT3JQ�(E5�ՌRT3JQ�(E5�d�5�ՌRT3JQ�(E5�ՌRT3JQ�(E5�Ռ��ՌRT3JQ�(E5�ՌRT3JQ�(E5�ՌRT3J�^3JQ�(E5�ՌRT3JQ�(E5�ՌRT3JQ�(Y���/��"�X���b�_,�E~��/�I~��/��"�X���b�_,�E~��/�E~��/��"�X���b�_,�E~��/�M~��/��"�X���b�_,�E~��/�C~��/��"�X���b�_,�E~��/���W�z"�X���b�_,�E~��/��"�H��"�X��j������`U�|8X���* V1\��8X5��*"Vq�ʈ�UG�B�`U��8X��p�b�`U��8X���*(VEq�J��US���`Uýʊ�UW���`U��8X���*.Vuq�ʋ�U_�*0V�q�J��Uc�"�`U��8Xu��*4V�1<��8X���*6V�q�ʍ�Uo���`U��8X5���`U��8Xu��*<V�q�J��U{���`M!�w�!��`"�$�`�"�,�`#�+$���`�D>��`�F2X�֋$��&��A6[ēlf^d3�&���.�/�����̍lf�d3� ��'�̼�f�M63��H!cp!��+����f�N63��y��̋lf�d3�!���4�����̍lf�d3� ��'�̼�f�M63��Hqcp!��+����f�N63��y��̋lf�d3�!���9�����̍lf�d3� ��'�̼�f�M63��H�cp!��+����f�N63��y��̋lf�d3�!���>�����̍lf�d3� ��'�̼�f�M63��؇-�����U�����ST}�b�����)���������u��V�!�����\Hn�Jr37�����̃�f�$7�"��7��|Hn��Fr3�����̍�f�$7� ��'�ͼHn�Mr3��W��׉��\In�Fr3w��y��̓�f^$7�&���M\�Hn�Br3W�����̝�f$7�$���ͼIn�Cr�7�����̕�fn$7s'����<In�Er3o��������f.$7s%��:�l��8��8��8��8��8��8�3��3��3��3��3��3��3��3��3��3�x�c�c�c�c�c�c�c�c�c�#�:�:�:�:�:�:�:�:�:�:㈗�8��    8��8��8��8��8��8��8��8��8�3��3��3��3��3��3��3��3��3��3���c�c�c�c�c�c�c�c�c��u��k��8��8��8��8��8��8��8��8��8�3��3��3��3��3�y�+0������u���|��e�r��U���ST-��NQ���7E�r��U��ST<(�B�"�7)�|H�"�
.�\s%�)��I��A�5OR�y�r͛�k>�\��R���r͍�k�\� �')׼H��M�5R��CC�)�\I��F�5wR�y�r͓�k^�\�&�)W�ɡ���k��\s#�;)�<H��I�5/R�y�r͇�+����B�5WR���r͝�k�\�$�)׼I��C�y�hp!�+)��H��N�5R�y�r͋%y�7K�|X���ƒ4����$͍%i�,I�`I�'KҼX��͒4�$�W�m����$͍%i�,I�`I�'KҼX��͒4�����$ͅ%i�,IscI�;K�<X��ɒ4/��y�$͇%)�o,IsaI�+K��X��Β4��y�$͋%i�,I�aI��K�\X��ʒ47����$̓%i�,I�bI�7K�|X���ƒ4����$͍%i�,I�`I�'KҼX���.�|���� sad��̍]���2vA��.ȼ��7� �!o��|#o�y�\��F�0w�y�7̓�a^��&o�yC����B�0W򆹑7̝�a��$o�yü��C��7򆹐7̕�an�s'o�y�<��E�0o���7�獼a.�s%o�y����A�0O�y�7̛�a>�XSm���7̕�an�s'o�y�<��E�0o���7�卼a.�s%o�y����A�0O�y�7̛�a>�q}#o�y�\��F�0w�y�7̓�a^��&o�yC�������\9=��'s��d��s��������㈻�8��8��8��8��8��8��8��8��8��8�>��>��>��>��>��>��>��>��>��>�x��c��c��c��c��c��c��c��c��c��#^�������������������㈷�8��8��8��8��8��8��8��8��8��8�>��>��>��>��>��>���-�Do�Do�D���Z��N��N��N��N��N��N��N��N��N�����������������������Do�Do�Do�Do�Do�Do�Do�Do�Do�D/n:ћ:ћ:ћ:ћ:ћ:ћ:ћ:ћ:ћ:ы�N��N��N��N��N��N��N��N��N��N���������������y�0o���6@<���� se`nl̝m�y�0O���6����� �zc`.l̕"��>�#��c��c��c��c��c��#��������������������㈏�8��8��8��8��8��8��8��8��8��8����5Q}S}S}S}S}S}S}S}S}qQ�T�T�T�T�T�T�T�T�TG\��1��1��1��1��1��1��1��1��1��7�qL�qL�qL�qL�qL�qL�qL�qL�qL��\�f_�!u��:CH�!��Rg�3��B�!u��Rg�3��B�!u��:CH�!��Rg0O�!u��:CH�!��Rg�3��B�!u��Rg�3��B�!u��:CH�!��Rg0o�!u��:CH�!��Rg�3��B�!u��Rg�3��B�!u��:CH�!��Rg���e"u��:CH�!��Rg�3��B�!us��Rg�3��B�aݺ�k��u�v�.����p����u�v�.������~;X�փ����`=)>Xo��-��MQ���7E�r��U��ST-��MQ���7E�q\��`�y0�<h�C΃!����`�y0�<r9��C΃��y0�<r9��C΃!����`�y0�<h��C΃!����`�y0�<r9��C΃��y0�<r9��C΃!����`�y0�<hޜC΃!����`�y0�<r9��C΃��y0�<r9��C΃!����`�y0�<(�k���D΃!����`�y0�<r9��C΃��y0�<r7ҵ���̓tm��k�"]�7��|H�b��ST=�OQ��>E�s�U��ST=�OQ���7E�r��U��ST=�OQ��>E��d���U\I��FB6w�y��͓�l^$d�&!�	Y������͕�ln$ds'!�	�<I��EB6o����Şۧ����U�����s2ST}Nf���ۧ�zn���}����)��ۧ�zn���s2ST}Nf����LQ�9�)�^o���}����)��ۧ�zn���}����LQ�9�)�>'3E��d��z�}����)��ۧ�zn���}����)�>'3E��d�����U�������)��ۧ�zn���}����)��ۧ��ˮST�i�)�>9E�g ��z�}����)��ۧ�zn���=Qm�*��3q!!�+	��H��NB6�y��͋�l�$d�!!�=�OQ���;E����U�����3�ST}r����)��ۧ�zn���}����)������Zn������~�
R��@�T C*�!Ȑ
���ۃT C*�!Ȑ
dH2�R��@�T M���R��@�T C*�!Ȑ
dH2�i�� Ȑ
dH2�R��@�T C*�!H�g��@�T C*�!Ȑ
dH2�R��@�<�=H2�R��@�T C*�!Ȑ
dH���A*�!Ȑ
dH2�ꔺ�:��:��:���N��N��N��N��N��N��N��N��N��N�py�)��)��)��)��)��)��)��)��)��)U\tJ5uJ5uJ5uJ5uJ5uJ5uJ5uJ5uJ5uJW�RM�RM�RM�RM�RM�RM�RM�RM�RM�R�M�TS�TS�TS�TS�TS�TS�TS�TS�TS�Tq�)��)��)��)��)��)��)��)��)�T���� �� �� �� �� �� �� �� �� �� �.��.��.��.��.��.��.��.��.��.�x�`�`�`�`�`�`�`�`�`� ����������������������� �� �� �� �� �� �� �� �� �� ��K�Z&�`�`�`�`�`�`�`�`� .���������������������� �� �� �� �� �� �� �� �� �� �.��.��.����)�4a�4a�4a�4a�4a�4!�^j�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�{��N�N�N�N�N�N�N�N�N�:M�:M�:M�:M�:M�:M�:M�:M�:M����4a�4a�4a�4a�4a�4a�4a�4a�4!�^j�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�ӄ�{��N�N�N�N�N&�!�!�!�RE�K��r/5�^jȽԐ{�!�RC�K��j�^jȽԐ{�!�RC�K��r/5�^jȽTS�RCU�/Q�mS�mS�mS�mS�mS�mS�mS�mqSe�Te�Te�Te�Te�Te�Te�Te�Te�Te[�U�6U�6U�6U�6U�6U�6U�6U�6U�6U�U�MU�MU�MU�MU�MU�MU�MU�MU�MU��S�mS�mS�mS�mS�mS�mS�mS�mS�mS�m�Re�Te�Te�Te�Te�Te�Te�Te��=��yO��{2!�Ʉ�'�L�{2!�Ʉ�'�L�{2!�ɘzO&�=���dBޓ	yO&�=���dBޓ	yO&�=q�{2!�Ʉ�'�L�{2!�Ʉ�'�L�{2!�ɘzO&�=���dBޓ	yO&�=���dBޓ	yO&�=S�Ʉ�'�L�{2!�Ʉ�'�L�{2!�Ʉ�'c�=���dBޓ	7�����̃�y��0/�����|�~�-�OQ���=E�r��U���ST-�OQ���=E�k2ST�&3E՟蝢�o�NQ���3E�r��U��?ST-��LQ���3E�r��U��?ST�^�U���ST-��NQ���;E�r��U���ST-��NQ���;E�r��U���ST-��NQ���7Eu�~��K�+S�+S�+S�+S�+S�+S�+S�+S�+S�+�V��T��T��T��T��T��T��T��T��T�J|T�2U�2U�2U�2U�2    U�2U�2U�2U�2U���^��2Q�+S�+S�+S�+S�+S�+S�+S�+S�+qQ��T��T��T��T��T��T��T��T��T�J\U�2U�2U�2U�2U�2U�2U�2U�2U�2U�7կLկLկLկLկLկLկLկLկLկ�]�+S�+S�+S�+S�+S�+S�+S�+S�+S�+�P��T��T�����)V�;���ސ;�!wxC��'wxC�������r�7�o�ސ;�!wxC��wxC�������r�7�o�ސ;�!wxC��7wxC�������r�7�o�ސ;�!wxC��wxC�������r�7�o�ސ;�!wxC����^��1�;�!wxC�������r�7�o�ސ;���ސ;�!wxC��������k�[�!o����j����k�[�!o�����k�[�!o��������k�[�!o�����$�E<HP�I�2/�y��̇%�z�9q!A�+	��HP�N�2�y��̋e�$(�!A���>E���ST��>E��ۧ�z�}���ۧ�z�}���ۧ�z�}���ۧ�z�}���ۧ�z�}��ϷOQ�z�U��OQ�z�U��OQ�z�U��OQ�z�U��OQ�z�U�o�����)�^o�����)�^o�����)�^o�����)�^o�����)�>�>E���ST��>E���ST��>E���ST��>E���ST��>E���ST}�}���ۧ�z�}���ۧ�z�}���ۧ�z�}D��~�����̍e�$(� A�'	ʼHP�M�2����sVq!�+9���9�N�1r�y�s̋�c���!��9�\�9�J�17r���s̃�c���"�79�|�9��F�1r���s̍�c��� �'9Ǽ�9�M�1r����s̅�c��s#�;9�<�9�I�1/r�y�ṡ�#o�s!�+9���9�N�1r�y�s̋�c���!��9�\�9��Z�č�`��`-�'k��X��Z0ւ�k2�ą�`��sc-�;k�<X��Z0/ւy�̇� ���U��LQ�}�U߷OQ�}�U+l���6E��
���o�MQ���U��LQ���U߷OQ�}�U߷OQ��¦��[aST���)��V�U�Ɍ���ԏ{��Z0Wւ��̝�`��d-�k��Y��Z{Mf���d����}���ۧ���}���6E��
���o�MQ��¦�zMf���d��zMf���ۧ���}���ۧ�V��wQ'zS'zS'zS'zqӉ�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ^�u�7u�7u�7u�7u�7u�7u�7u�7u�7u���M��M��M��M��M��M��M��M��M���S'zS'zS'zS'zS'zS'zS'zS'zS'zS'z�҉�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ�ԉ^�u�7u�7u�7u�7u�7u�7u�7u�7u�7u���M��M��M��M��M��M��M��M��M��a���sLԉ�ԉ�ԉ�䯫��u������U»j�!}��Q�~/�r�I'����	���qB�8!}��>NH�\���qB�8!}��>NH'����	���q̍>NH'����	���qB�8!}��>NH�����qB�8!}��>NH'����	���q̃>NH'����	���qB�8!}��>NH�<���qB�8!}��>NH'���&�z��I�&�y�&yț�!o���I�&yț�!o���I�&yț��͛�!o���I�&yț�!o���I�&yț�!o��o���I�&yț�!o���I�&yț�!o���I�~/�c�ț�!o���I�&yț�!o���I�&yț���!o���I�&yț�!o���I�&yț�!o��+o���I�&yț�!o���I�&yț�!o���Inn�I�&yț�!o���I�&yț�!o���I>�(��K����)��K����)��K����)��K��j��w�����)��K����)��K����)��K����)�����Zn���j��o�����)������NU /QHSHSHSHSHSHSHSHSH�R�T�T�T�T�T�T�T�T�TR�U�4U�4U�4U�4U�4U�4U�4U�4U�4U�U MU MU MU MU MU MU MU MU MU a����6QHSHSHSHSHSHSHSHSHqQ�T�\I��F�5wR�y�r͓�k^�\�&�)W\�H��B�5WR���r͝�k�\�$�)׼I��C�{/u���R��z/u���R�����ST-��LQ���3E�s�U��ST=�OQ���;E�r��U���ST-��NQ���;E�r��U���ST=�OQ��>E�s�U��ST-��MQ���7E�r��U��ST-��MQ���7Euh�|��!��!��vȦvȦvȦvȦvȦvȦvȦvȦvȦv���������������������xk�lj�lj�lj�lj�lj�lj�lj�lj�lj�,>�!��!��!��!��!��!��!��!��!��!�~/�s��������������������h�lj�lj�lj�lj�lj�lj�lj�lj�lj�,��!��!��!��!��!��!��!��!��!��!��vȦvȦvȦvȦvȦvȦvȦvȦvȦv����������������������s�������}r�,��Y�����g!��Bn���>3On���>�}r�,��Y�����g!��Bn���>3/n���>�}r�,��Y�����g!��Bn���>3on���>�}r�,��Y�����g!��Bn���>3n���>�}r�,��Y�����g!��Bn���>����g"��Bn���>�}r�,��Y����w�B�U3�UY�ۛ�Y�!k0d����5�C֠��C�`�Y�!k0d����5�C֠��C�`�Y�!k0d����5�C֠��C�`�Y�!k0d����5�C֠y�C�`�Y�!k0d����5�C֠y�C�`�Y�!k0d����5�C֠y�C�6y�0�mÐ�C�6y�0�mÐ�C�64o�6y�0�mÐ�C�6y�0�mÐ�C�6y��|x�0�mÐ�C�6y�0�mÐ̶E����B^0w�ݥ��B^0y�,����B^0y�,����L�ݥ��B^0y�,����B^0y�,����L�ݥ��B^0y�,����B^0y�,����L�ݥ��B^0y�,����B^0y�,����L�ݥ��B^0y�,����B^0y�,����L�ݥ��B^0y�,����B^0y�,���w�M�ݥ�w�C��yh[E^
y(�E���B^
yȼx(�E���B^
y(�E���B^
y(�E ��E���B^
y(�E���B^
y(�E���̇�B^
y(�E���B^
y(�E���B^�^�5��B^
y(�E���B^
y(�E���̅�B^
y(�E���B^
y(�E���B^2W^
y(�E���B^
y(�E���B^
y��x(�E���B^
y(�E���B^
y(�E s�E���B^
��6Q��T�2��L�+S��T��+S��T�2��L�+S��T�2��L�+S�J<��L�+S��T�2��L�+S��T�2��L�+�R�2��L�+S��T�2��L�+S��T�2���[��T�2��L�+S��T�2��L�+S��T��+S��T�2��L�n�������!�C����丹�?r0��`������!�C����?h.��?r0��`������!�C����?h���?r0��`������!�C����?hn��?r0��`������!�C����?h���?r0��`������!�C����?h��?r0��`������!�C����?h���?r0��`������!�C����?h���:E��^��ō���Qr�*�FUȍ��U!7�BnT�77�BnT�ܨ
�Qr�*�FUȍ��U!7�BnT�7�BnT�ܨ
�Qr�*�FUȍ��U!7�BnT���R�ܨ
�Qr�*�FUȍ��U!7�BnT�ܨ �  2nT�ܨ
�Qr�*�FUȍ��U!7�BnT�ܨ2WnT�ܨ
�Qr�*����u6�u6�u6�u6�u7}�M}�M}�M}�M}�M}�M}�M}�M}�M}��]_gS_gS_gS_gS_gS_gS_gS_gS_gS_g������������������������������Y<�u6�u6�u6�u6�u6�u6�u6�u6�u6�u/}�M}�M}�M}�M}�M}�M}�M}�M}�M}��[_gS_gS_gS_gS_gS_gS_gS_gS_gS_g�������������������������������{�?�D}�͕���q�6wZ�A��<i�-�e`>58a���;E����U��KST���)�EY��EMeQSY�T5�E�UY�T5�EMeQSY�T5�EMeQSY�T7eQSY�T5�EMeQSY�T5�EMeQSYTܕEMeQSY�T5�EMeQSY�T5�EMeQ�P5�EMeQSY�T5�EMeQSY�T5�E�SY�T5�EMeQSY�T5�EMeQSY�T/eQSY�T5�EMeQSY�T5�EMeQSYT��EMeQSY�T5�EMeQS]�[T��T��T�R��]
յ4յ4յ4յ4յ4յ4յ4յ4յ����R�������������������������������ki�ki�ki�ki�ki�ki�ki�ki�k)��.��Z��Z��Z��Z��Z��Z��Z��Z��Z���K������������������������������R���������������������������x�ki�ki�ki�ׁC�:p�_���!8���u`����u����ׁC�:p�_���!S��#2u2uo�^j��}��}��}��}��}��}��}��}�Խ�{�!S�!S�!S�!S�!S�!S�!S�!S�!S��L݇L݇L݇L݇L݇L݇L݇L݇L����RC��C��C��C��C��C��C��C��C��M�K������������������7W��o"�C����?r0��`������!�͍��!�C����?r0��`������!�͝��!�C����?r0��`������!�̓��!�C����?r0��`������!�͓��!�C����?r0��`������!�͋��!�C����?r0��`������!�͛��!�C����?r0��`������!�͇��!�C����?r0��`������!��~/��m"�C����?r0��`������!�ͅ��!�C��LY�ȔEȔEȔEȔEȔEȔ��2e2e2e2e2e2e2e2e2e2eanLY�LY�LY�LY�LY�LY�LY�LY�LY�LY�;S!S!S!S!S!S!S!S!S!S���EȔEȔEȔEȔEȔEȔEȔEȔEȔ�y2e2e2e2e222222f^L��L��L��L��L��L��L��L��L��L��7Sa!Sa!Sa!Sa!Sa!Sa!Sa!Sa!Sa!Sa��TX�TX�TX�߉�;q!'.��ą������w��~/�����rM���*�醇t�C��!��nxH7�\膇t�C��!��nxH7<��醇t�͕nxH7<��醇t�C��!��nxH7��膇t�C��!��nxH7<��醇t�͝nxH7<��醇t�C��!��nxH7�<膇t�C��!���EC�y_4�}ѐ�EC�5O�y_4�}ѐ�EC�Ҧy�6͋�iޤM�!m�-�OQ��KST-��LQ���3E�r��U��?ST��}�l�T�C*��Me;��R��l�T�C*�!���vHe;��m>T�C*�!���vHe;��R��l�T�C*�b����O��R��l�T�C*�!���vHe;��m.T�C*�!���vHe;��R��l�T�C*��Je;��R��l�T�C*�!���vHe;��mnT�C*�!���vHe;��R��l�T�C*۰>�K�/M~��=?և��#Ϗ���G����>�������>�������>�������>�������>����[?�Ǜ�kW�~���7\���������������������������o�o�~��~���~�O�~��~���~�/�~�ϲ~�o�~�2?�5���)������������������������������?�����������?�����?O�      B      x���ےɕ-��� 	���Q,�s4�RW7Y�y��d��M��PSV�>{�ow #[f�b��L����}Y��������:����i?����|�U3k�?ϖn���_O����O�u�/���t��_���O_���?����6?����F��ۭ��������E_���_�?.�����/���8܆����r?L6��p�l��p�ޯ��/���;��lN�뽿�.���~�uҿl�}��iҟ��I��&��A_����z�����~�@t�߆�}/_���z��/�M���-}�=�@��_'�7����Oi�mW���E�n��{��v;_����������t��a�o��5�ٿ�g����lr���'y�{��9�6�����k�O��/�BX]`Y�_w^fY�?���n�����/��O߆�����۰��2ҿ�|�1����?w�~/����F/�~��?�'��7-V��݆���5��v��i:�|�w���u������z�]�
.�}���ȯls&��7���Ù>�tB�Do�^���On��v��@�/�0п��mw�oA;e����]o�j����j�ײ\���ki��̫�6>�n�m//e����~�V\G^T�߶����}��Q�����H��w���p��ɕvٝVi�����g�i�~��<�.|��M���K*��z�_�O�"�-�����	����w���F��8���Z���;Z`���~A��|�Ӷ�����sZ��^U���o���V8�;zU��	���O��z��٪�]w�����7R�Ko�x����=���mG��/tD���p��Ñ��~��C��Nsz<�h��@�8ô1�x�s�`�蜮���j��M;{��hQ����;�E���=L��&�?-��l�����@t�q@�Ss	/����������&��h?��7�����3@��{�S�iK'��e���H_��&�����1�)�ң�J��ߡ�r�{Z��r�\�
-�j�v��
-|����x���b�{;/���zF4��y�`T���P�i�e����Q��W��z0}�܇ ���b_w�+��;:/zaЖ�����7��H��~�bcҙ�[�Nݭ��=`�N'_e��v;l��d;�RЦ]x��;[�Ӆ�䉎���N.�0 �j���9�MuU�i��D�ΗY�g��関�����UX~Y�We��A��i��G�`�P�v��v��?�-�}.�ϗ��	�߹�����o�ݨt7//���]�;|����O�;�p�-�o��|���v��/�nڨ�X��B����K�J�79��M�5�LS5�9ݰ�zla��0����fW�����+��~�Ծ�lk���Wv�է=<����}�i�#.3��	�ް�/$7Οz<,m#�Q���{O�9=t"�&��������E�ό}�z<�)��y쑴t%�t��=��#�u�����-ېtҍ�*���L��T��n?���t���ӆB��+_�u�o�w�җ�{�o������).B@��<�!v��]+a���QdI�������V����^��'��(��'�zZ0:�O�����W�e%����%t��� �����v=��i���5�S�~V���ʮ}ek��z�I�NI�w�t��������K�G�_x�G�7&�sٿ�C����	2�� ]Q;�\�G��_�&�O�[�b�sؿ|��(!���덾�q�l}x���({b����Jg�?�o�V���[R�XT�z>M�giy���@�z�$�#�A��BAI��s��~�ݣ�K����y��p[�	��(�2E���������>�C������͎�V�Տ��KOcҿ�~��/��~��dY&�9��o����R.�Xi�|nn�ٔ�L�r�ݴ��5-��n�S�Aq�z������ۀ��~���V�N���0��b����s��U�/�����AbE�3/kK;1���Ӂ�d����r������3�b(>iWI�o��%�Tw��"����](g�ݎd��+k�1�N����.�*JT9��f���K[���al5S�@q��C�i�v�\�K�fV�n�N�P�b��'�\��d�R�]SefTdP�j6\*�u��P�p��������8H���J�E�nOkK�K�M�t��l:��nk��腜Q����Aa���[���,ۘ���v6�-�մ�W�z>z�ש��ۊ"]�w[�i�i�n�t�fkn��D_�-ZX����M���Q����g��T�Ig�7�@���5��t��͆�j�%����ܜH닪��+�S�[�4�'; vEY�N���4�cJ��oq����x�L�E�Ұ����~{�g^��"Ɇԥы�!D<�S��m�k����DY<�����L1א��C�s8�P��_�wG�w�"d�?�$���ߤ�� �B�{8m�t$�.~P���B�e�[�n�^:�c9����\tP4EQG��\�ޏ�5z��@8 ���ZNW�f�m5_���;K�}ay���t�l�j}U3��|�û�]���[��h/��^T�'�V��S�I���wj%�W�{h_��s�ч�YK��R���*����Ea����Ej)��v��=��Ϻy�Eҧ�o����N_�o��rT��l�����RV6�.�j��
x�H�-�%6�����8z9�k�������⽕���hE8��,(��m��mt?��B��{������8�W~�H$����%E�k��W�T�*�PZO�~��|��S
&-Ҍ�|1���S�E,"~ W�z*����N��96�rn��+E~HE�#�DT�q��^?�K�M'��bL���&wk�Іh{��Km��S.��t��:��+�Պ2+�W��x7wQ
�Z<�K�>2ҝ!�ݳ*��]��z_���v�1�\'����{��\���>+ �=�Pl9W������"MB������1*pt����UBKcx�_ф�R{��ǧ�]��]�:��u��Bi�sC��=Jz�t�Sb�Yb�g.!,=Ƭ�k�c��ׁ�i����'ϟ�'z�xo���s6�->2�J��_h/w���NA1#���5]��tM�-U���r�X�:�RAz�>�?�mş��������_o���ㇹ�s�ز��r�ຘy��j�C�G�ˀ􅳸#N)��#��7 �^v?��O����=�
\�9�9�y��	�i���h��~�	��iK�̴��v>^6���ŦCȖ�5�J���ܬ�R.�[�קT��۪���W��\�7�6]�x��1[WZ,��_ӱ>?�=��؏�9G�`��g��ξ��N�}��������ޫm��[�:��-�Ns� W�z��i�Ȫ�4�B��������Ϛ�w[�bS����	YƇv�����6r[�i���hqn�g[K��P\ib��ݜ2,�H�x��z���x^��?ڮ�z�l�Վ�?D���N��vV����-���X��UZ6]k����b����?6hd��M�1syK��Yȁ��r�6��!��P�1�����2ƻ0�����1�K��+��䎾�"}�����a��U��-�&U�M�$섔��cw蹛�!�Z���ކ.�/��!u��ۿ`��=���6;*��)!��_O�������Iw�x�E��A�g��^[l��vGIp�C5����TU��iבҡP���J���p��z�4���YTou(�Fʟ��*���8Y.*i��y�h�����������g�hO!CG���]�!e�%�ux0[�š�]�h^=o%OƄ�~����<r:���i�e��o�����Ur�M^NڬĠ�C������C��t�U�l=�4)E��gs:�^�o��q@3՗)RXj=�(y�<P����p����;�q?���"f�7�z��)U�p�sJY1�5.�R)^�1n��^�$8Fҁ������tEƌ2ñ��"J��gʜk?P��uM6;������R�`[�KCvC? L|U?�}J��H����8����mɹ�f�:b����eǩ�j�'ë̅�ǝM/��O:O�:���:�`2��Q��x���    ~��;>�i�A!���8�!f�a�e>���<J��������p�ܼ=�*���i����>1������`�2��<s���A,0��[Z�}���#��=y^$^��{VƊ�}L%�Q��U�E=~Y�R�YW�ҡe��q��߅q0
�}l;)^ȼ��1�,��<F
���;��44$�Ғ�Q*��^&t��N���� ����3m�[�=n�A���}�p�h�+��ޗ~�r� ��/'�h�'r���P�ky@3m��jI;jl�S�C�GG�UiY��O�ع7H���c[��#��j��p�G������^�nl�a���7�з�Jg�N=Z�(_�0d����n�sO/�q&���kP!vt5���r��:˔!��ŉ_K��/uM<���Z���%7nM��Nۖ�N��^s���|�����.4|�f�h�m�~�T���8��% D�#���Kx��2��)Y��rL�v!��������>$��݁�=W�7�1��öG��x�9��_徖�;��HGh���Mq����S���C��.�v6~R�~��g�Sp5qy	��Ujd ����Vd����%�b��(�h,�\�������@B%-4�#���I��^l���<��#G���X��F��h|1�rXJ:0%m��S@����7�ށE����Ӂ���I^ڗ�+�?y�I������ҟ����]�;��qm;qC�v܋�r�O3_O�f��� y�.e�z'8W�ۻA�;�Ҷ�� C|�,z1h��SZ�N����L%�#�=//gʹC��Ec���,ǝ���su����	RzA��,��J�].��e�w|Q�x�L�p'c���"cq�p.t%��?Ђ�� �u��K��L�~�	H�/  (� c"A����t{�Cʎ��<p�%�����U�r�Y[-�s�\�����J�j��hO𐂟'�<��<Ej{1ҦǙ�v�e�u���+.&9�����c,?�ީ����*Z��~8scF�N��	�FF�GNP6�ҳ��o=:{�Ǔ����y��-0����FQ8�T�̗A�G�l�S�.�x�ݗ���y�;��m�~�N��Ŕa����+')���HZ���!��U��<�Ǭ�̈���&I�H�_����$ED�M�ХZ7]׶��p�*������R%�O���!��N?_O�		)#,qB�����_��8��7��+�#����bPf� @)y�4�<b��'l�� Kp��nR��ZY�t�=gtl�D���"���Y��T�����Z�=����μXF[� ���'�(���!]g/WA�_j}G���
����=����.\����%e���d�Ƨ���E�!I�^$Pw]e�s�����-�{��3O�i��.))�����`j�jڭ:�V�9]����	N���AҖ���K�ULU{8�t/�]G���i�&�;�}��U�īO	5UL��t§���zr�c8B!����9q����M�I[W���c��z}�����	��H�7 �����<g��Dz����QY,|��h �x�%�M��7���}JU,���VJ(��hح
`�9�;T֌A�SYCw���Q�J�������B#�<\���`-9��<i3 7��B��L��׼u����I�q��nW*��2u�*��q$0OG�U3L�>YU��|�Ц���YzS|���X0N�`��A�����^.#/Gmj�����XA��n8�x_18��};m��K�j�HZ���9�Oʀ�i����R�F�6\ڊ[��m���9qʦig<��y��Y6��Y�+�π�-�A�5=�Ӟ!�2v�|ӓ%�[*�G!�� ]LJK�w�]s�ץ?���L��6���ĭp�H5rJ�����p�J�v��G�H*�k�έ)s��We�W��ǆQ�y�Q�">my��T�s��-3	�n��4�|���	�p�-���"9�n��B\�=|��>���Ί��Az����;G��Ā�����6mW�N��?�}
�sN�t�� ֗��c����o�G��j��zz��k�#>k�:�
vП���J��{ǍP*^.�h $����I/�e��UӍý�T���ȄS�!��)��[����ǜ̔#�������	��m�:󘖹4.�U�y�8��@X���	z�n��捶5t���({r";�����w��
��빓4��hOT�6U�A]ۦ�n��k���C�ԗ�c�κ=���B4�z���΄���: �0�h))��YcJ1��<���E����RD����\�?]��uŌX���v)��k�p�0k�Z2G����dH�7d�x�9cX07�ѽ8Iy��"�x97.kS.L\(D�����d-h�Q�!�W��;�~@F���dZ�gHc�i�Rq�צ�`1�va>e�
�� �͠�O���%Gxh (O�Ø�"������Z�#�DĻPM��ѝܣ�B�[�:V	Ky_�R@3���{��R^���~kL�[@ ��z4*.Rm@'7�$��h�п?�_���n;��������|"i��$;��Ӊ��P�T�+�u+~`<�W���x�-�q!��?m�+�cJ�u����zt��HEâ��ri�K��)\�� �����vQ1��M���;;����e葊kpnLT,z�H{6z:5s��I"q���6��o�A{�^�&d��N��|9
<��zWq���W+Y4�x��H�b^9�Cۉ|���\�$�ֻ��ʲ>��m
����֝�+�2Z&�ⅱ�旡tN�oO$1A�ch�&o�ru5��n6�/Y��dцF��gJv�߆�$C�����3������#((Ϯi�U#�%�>1�I�2��#�?�we�	��ߞ�7�w��d+4�s��z�?hýR����[I�ߤȔr[�W�ts�ō��6��'�� ��6�C�O��:h�fi���pγ�DN��b �P�8���|���b�*_y�iL'���t����WtF����^�;�R��mr���Q�~���������_�����{��A1uͭ�K�->8թtYt�d]�!ʹӄ|Q��'`�b�3���2���M9�������v
uxm �����g�Ɲ� Ƀ�;z|��<�{9�1���D���f./�ԛV�N(_uU��h:�H���s�K���H<���,o�\���,i䠲�Lp�*��t��}ԉʁ��` �M�?F9�0��E�jHSp��KŘt�ԨE�ބ�,���M �e��[&fJѶ����a���TXg\�"A��DN`6���G�4���%(����?��D4�e��7�V�&-�D�g���zU�g��c�
ʅ}p)���
���U�)+�~�.\�_lqñShʧ,͒:+�h��S!E�	�L�0�+]�zD����~?
hXY0�Ҡj�N�)�7LPb��U��,R���*�S
�ժ��Z���h^E�d�u�}12-C�7�|���I#�}bI��,R�U��cg�XW����~�-�����q�&5?�+�*;�prj:C��H�r>���RmЁ��ٝ!���Y��|���V�2)b���].I.����_O�o;+;��c��~u6�wȍ2
�����|N���~<u)��D�v�4�^�!P�8�ʰ�@
�����f�4�Y�����=v5�,���,�@�E�4��_ɲgy���$]l�˩(��'�X�̕���P^����ǱuHIx7��c��L<Ŭ�۰9Y�vB�-׋�������̓䩠�}e<���
�uI�����8�tg�/k�i��Ƚ2�aCG@Ԃn�9�tuӍ�������2��r�a�=��
�3ܢw�:�+��+Sji
m��M��rbhSrz�	 $(��0c�ea�a��=�B��QG6���Yu��UC��U1uJ�6=;�/{&v��(��CE�BU�.��1��ݢ��b�r���+�?��X�Pǈ���@N�(��32�+(�&01d͟��e���V��@6��~�V�rU)�髹���X��;�^�����ts� � ����!���� h�u�dJG����^d    o 㐀��g���A��٩裣��n�?ԒA[i':H�OL�*����X�f*�
<;�����My6]��B�I;ˤ��kbM.j��է��R��yt�07Ȇt:�A��.��-��+�,��R�/ig0�ܯ
����V)�P8�F��pmh�������Xa��5�U����,��z5�^�R�߭��ޤEl�4��;ֳXd�m�jTB�pax�7���~��e���ݥɃ��l��R%�Ν�~��1~IC}�/ �7�p,��E�X����.��ݺ��-� �df��C��1��-gH8O�OఃUt��9o�ʀ�1�:��)N��0��I�Ca�GܡC��s����.y6������f'w�.���Y%�I"��EvB�7��QM�Ϩ��O�Y1�S���'|�VІ3��[K�*��?t�g&�k���Tϧ�2�����.S.�����5��3�3Z	���x��1�%���M���S������2Yt
 �Q1Ut�UMY~�+:�7	7\�q�����So (��ࢌt૜������o�p��G�߰$���}"�bJo\�j��n�չ[�	�,a+n����4��j��j\y�_+��T�{��	�QQ� r���3��
��(%� ��R���%2���_��q1���hR�-lUeU�X���e	��yW5�j�O�L��r^�:�Nd����4�P��?Q�hQ��uJ�7����Ⱥ΢O|L�P�S� 3�*|��x���N<��ߺ�XU�vޖ)�_�~i1�k����ܗ���l�d��'�=�"�����ȼ��#STRc3\6����y`c@�.�Òvi�*>��Q.���;]^Z����D�I��@�q`b��[;�[�$�����T�]�i�"�Ӥ
7�!qZ&�5��r���O��aA�`4l�<�v}Y�bD}q�k��/�n�#*��Ek�'�T$��'8K��3͐M̗��$|���%T�6�#N�,�B����{&J��j����`y
(W�]*�}�rKRE� SL�19� :��"3z�=��g���¯'��H
�؏���ɯ����,���oJ��W�(DM�6V9�U����P�!:��Ӱ��߷.S"�ʭ��6�X8�kA�'�I(����H�p0�A�.��Ԝ~�������r�}���hmS�kS�Ya:{}d$�b���*�nr¦>U%��r���!�[���Ì~�@+��I�H��A����F갓��xb�2x�f�r1�	S�ЦL�I��S�l����$x}�[��$
Ytt��^�}��(����C�̾��z���� ���լ2�rr���3uTi-3�'��X����Q�1��E�a9�Fdb��O	���Z�xQŖc&�"E��^�s��dx;�ט�"F���U*�T2M&���j"��K�pI��~��G���O��o�{R.!���[����%`�Q}�9��PŌ�jW�(wc���US��C�o ���C=:�ީ2t�N̥��b7M΍ܳ{<��x���kE++�~o� H���i�2�"`�7�,�s2�m.��żZ��B竔P�(���ޛ�������ў�ICS'Q�`��8�����00ڰS�(ػF��Ut��CƝ�Le\�+���A_(�M���t[W)�y��`�
>UO+��55�
۪Y��W)1_��Bt<�Yd���]Y±r]��uZ�3�Q���=*{����He[�k��f=ۡ��Y��[��H��(E2�c¤A����Q����Y�I;zPT7W��og��ӜR�բ2�n���/�<��<:�<dP�̢Κׅ��q6Zo�?k�h;BҡY��׆Ns�щaV:�`��7٧az��m΁��9�!��@+	���,��� ��mGq���ɯ�J�'=�Bc҂�Rd+Ub����߭���_w��	��D���$�x`�쬅��;�d0C�w�J�x+��V�SR��v�i��iƭ
RNO)�ظh;�5�S��Rk>g��ͼ�c[-�O����!�0���H0����"GW"a�U9��GƼ�eoMz�N�Ne)�-���2/�M�F/��"��*6���z1�ܕ����8�j�9�f�83<��T��#��Gץ�1]�+Q��N�F�_T! �Nÿq��Ǭ� �[3+�l$��vt��ۉI?���y�4�z=YSqA��6^��ܬ+��z&�7+)nj�v����@���x�Q��8��:(k+�3M���$�ᩩ�f�H��q`�j���Z��I��Tf�1��+�iAdT�w�@�:�$AU�S)?*KA�lG�斓]�Th/T9��R��0xl� ���(	��
�e��\�u�xѵNE�3ѻHʼ ���W��[��;���xV�ݜv�A�?ēZ��p����.	`p��*�|�a߇�E����T�9YN:��j�9�
����u�=�Me4vsYSH_Z��lܖI_1
(���E���� �G���В̍D�0<��I�S{��g3=pW�?���O�_"��~�PA
f7m�S�ff��ñ�!�R�Y�P*WlJ���-�Z<�~�f�\��[�[=�A6�/�-���'\�	����!�������ĕ#��0��t(
kL�e t�t�C�u�U(��HzU
�IK�<̽ƀ�Jē!`�[z�@��A��'&2�Sv��r,�A���bL��ix
/�[�	�f��~�5���n�Ï�T�զP���{�%��N8��z<W���{ߛ����~���S�m܀Bu�u"3VS,5��ǫߨb�#Jw���a���o�����ZX)ܲY7���,�I(�T��;�@�+qcg|�<ɤԝ2��l�tn٢�'�n���x�|�r�M4EBBIo@ٱ'�D�6/ͣԋR��'��|Y��#�Tp��UiN��)��Z5e����/������������* ��P����Em����s���Ǩ�e��q'�u��׫�Oe�,IF���L��T
.��:�������8����/H��D���V�4�tHit�z?�	܆-�vBR�(މ�j<���5��Y�T���IR*�7���5f�5��3��t-/{yMpu�t���	��&%P5o��A܏"L2�����u\�aIFU0ߥ#�����`ʶ�^�l*�x��X�ڲ�ۭ�E��E�臽�2��2/�Œ
���
���0\���D_�Ӛ�����U=�բ^6�ڣ��m��[IMxwYvi l���[�q\�j��B\hC�F-P#�s��qZɰ���4�3z5O�$��~��h����9*�Q�����E�߉HTw�1T��7������}{�\�=k����=qh��s�d/@���kbx������ի�l��l�(�+����Xg��O�b��Vԣ�IGPY3q�tA&O��2�E�K�'�D1��Y8�;m2��������%o6��v�a:�Hz���ڰOR%=n��=��3��д5F9��(D��\-�8���(��#<R[���}#H�k����g�0'���S.<h��#� ��	��Z���r9hO�9*�ɚ�n0���!港�� mћx���[@��%��0f��#�en��W�YT�һ1u�p����q�I�(	C�?�Z�׼�Te�X�� L.�-,� �������̑�%`9c\�{���������n�Ĩ�]� �h����)B��Zb��^��5�%�����	����"���
?�{�kQfqT�!��~��Ε5�&� �ԯ&G ~��I;�����:�	\ �{X͂���>t��ʵ9m&���b��?��!Fs
9�N~��L�"���8�T�r���T��[�ܹ���|feQ��Zu�Ѵ�*< �tDXF͞0K����>+ܲ%y��g�k�f4����A+��Hvj�}ڒI���K�2�E\���9&qPH3A�i��cB��;�|�.�e�}p����l]�Ț����u��r��)	jO�V��eR��I�Y��0<޾L8&F���d0��pR�Yv��yrh[��PS�Wī�uf�-�­��tm�q�
Z�`�7�L�R!-����C\�    �����f�^�g����g�����\ɜg�'���i���m��V��{�ql0��䫀,�1��3�3��؛�[��?u�]W	��Ğ>��<.[���"���U�;*��ۡ��<2e�c~��h4��d�t�QT��0���N�2�t����tF�� 1��j5�è�M6�%�.�E�5�J�����RJR܄r`��o�R;�|�j4>�E�"a���o�֤��5�y3Q���i�E�̌R\��xT�f�p��b�����[w��y�iO����YLT�G�������__/;f���-���׈�#ߦIR��6�4��'�f���6T��%A��g�)>ff�Sj߄��8o^,�9�@Fw`�0�r� �W`����s���3���{� ��sW����U��BKpx��g��2!����Y�Cz����Vb�����N}�1�D8u�2aɎq`g��5�v�UG3k��N�2��j����R���(���Y���Ɏi��gfA��Zl����|�K��3F&s�MYXe'�Zz�����?t)@k%2��x�-�)"����=����K9�*�喌bJ+J
MI�[)O�F��*EY1�I��,E�|�N�B��+�c�L���Zt��c^�#Ƴ�j���I�A�f��̰�l�������0�G�������r_�&�@e:.�0�>����k�4���D�IP�R����.�E]�� ��ѽ}�K^��W,�`e3C�g�rz��}����]�Q�.@���93DD���hi�����N;7�|.���m�i!�OѺ�5��9oMe�oiy�UH*�V�dq��L�#3�����gӲ���+�@�cN��.��~R#��k�T�e��d����0�p3?-�fdyr�2��n������U7j([�޺	���Mn��Q�����r6��G�y���c�C�+YL����]�+��6�D���^��В�!Ht/۠�ğ��2�3��^`n�J�-VPH]���RB�T6x��^i�ns�s���L¢��`@W�"���>�7P`Ȧͫ��T
F	�vO�OH��E��}���<�)R��=M��i�9��e��Y�ߚ6h|��nS�[Y�(~�ȶd��А�E}2g��,��8�B�I��	�cd(��6zsj�7�F���Q̢60�k����޺iY#�d�@6�NM�6�n�fR�}:j��gN�ހ�7#?t�y�j�}��^d{��iaR�f~tj ,�Ä:V������^�ce�i�q�u#4�ol��rZ�g�%	�PA���eoM՜�&�$A�l�B�0.g�6��@/E���Ё���LC�T��d^��N��t�o1��)��N�'��C�T|Α'�zn�����E���m5j�������n�u�~�֡ON{��s�Ƶ���:���mϥ�2#�2V����1�J�5'c�<4���te.g�@�n}����v��`,f��*�̺swQc����E�>:��h���X@���2�瓚��
�%����d8��/�멍�s%	���Ʃj&��[�� @Ƨ&.+�� ��Ԉ#vZ�GN�f5m��Mr��T�޺��E&x�؂�}�}O���L���~�E'�>}p���gmb�"Q7Q�U1s�d~�xJ�'􋌈+|������-Z9l�ͽJ��QxpV=��R�p�z��`C-Ӭ���{��0� 9�=rNm��$���
jTcL�P`I���w��|��7�2K3T0I5ٽ	?�Q�,+.������z����z� ���{���Z#9���>�~X�'�i��,2Td��|[�~ ^��-�ÕYQ�te�� |i
^)	���>��ҭHЙ% �$��U`�y�݉i��Fqd3.�__��{n)
��XR��=���oh��1wAd)�增ak7�'nnhy2�-%&zR�p�oEڜA�t_�Q����2Y�Ŀ���^�U���Re�M��r�Y��(��]��
���]��TX��x,�����"�a�o��kj�=�ش�&�>5�k~�ɳ����T���4���׹�	.��PM�����_#[�soc��G�z>W���$K蛕���0?쟺d3#����4_�l���5o��%
84���I�l���i"o�7�Bj�P�]�h>��cp=�����T0�N\�"�m����	�9�0Ld��>�j�g�PJ�@���!;�%�	�'�Q�BpI4�h�zKo�5d��%p:u��>:��@ɻ;J/��.�v2�6�־QJ��G�A1,�r���eb�[j�m�w�VVf+��+�#��E�I�i�p�Ô�z���S�w�!NH^�Sf�`��FB��/G- �`�[ϻ*4p3�=͛<�����UN��j�y�`9��rj	l������񶤏�(IN�(��9$
m��Y-�'ϳn�M���Mr�����[o���)7�V���'���Q��/�i(�|]-g�"�u���Kx��q��0T��o�Wr�a�$�4�{��{d��ljB2�
��}R�r���S���,p�j�I�S:���T�5�Y:hv/?P�ko=G�O�HJ����y��H�/o��Je�Axℓ˦C��\�Z��\��W���LK��/��������4��E��iD�`�UȔ�&eC��|�����We�X��<�c�9�p��˥!�d.u$�΃G�T��"Lbʸ�u��������X@V>mN1�ۧrB�æȸ�T�^���%*�ؗ�V���}*��^f3`��,	K�ogSu`��-�_��Da�Z*�+��l�Э_������q�>+��1՜ƨ�Q��\n���\.�nٍ_"�����M���x�#܍v�J�x������2@�[�]4����/�0N��^D��q�E,��K��̩�N��\,h>��2Kz����C��P���Av�X�[�������A�u��� X�$�B}�6�1��2���h��W�y�(�7q�޴�i�_k�}1Ƈ[8pS�Ոw�,|�y�;����vڜ��0���r1���j�Y����-M�v�74��<����t1�f- f�`�+�]�K�γβ5�X�0��M6����Ʉ�ݫ�z7)C��}Be@i�D��Tz���T�S*������v��'��t��,Y0��%`8>��F�`�dnM<C��������􎣋�r��z�}��a�M'5�c���~�*=��`�Z*8��b<��`��{
���8[<h��sQ�z�j
]*�.�_�N�b� i�"��Z�BR)���\��$��%�	�nX"���%�I'P���(�]Lioq���l�Po�]�9N�<8.M�k_2Gejmn^B�����C'w�����ć6�ء��,�ǜ`��i�W`ݪZ0�i5n�R/^Ls��5r�=�y����	p��8���A��й�q�0��:��n����k�B;�bxKt2��T����8w&vێd��Z~&[�-�ز�ڏ���,�nWU����_��K�*`�s���:���q,
�rIj�; �_a���K!g'i�^ӳ^�đ�Ho{Yؗ�SF��r�O'�T�)�_^�3#�B/�f[W�v6��
V�u��X��Z�JL�߇qa�D��`��3��Z|��N)�W*.`�6�J�"�]b� �;�Bˤ?���� �ՂCn�}f�r�Ę�"�_�)w�L��sPC

�5fh�tMQp��+����lH�%�t�.��U�Tr�3	��&��r�j��*�yڋ �Hu9�B	���,!Ŝ�����Ů=s��Y$kZ�� 8k�L'���wT�(CoN�R8�j*v����[/�*�C����3�`�>d�q�3��"T�ϐ�2�ּ&��E��0��״V�x�� !	'Nd
��]�Ȓ��7���5>�f����z^�����L�k�3�Ë�}�p�5�Qk_��Z"����ڹ9�d����P\H�2�g`��E�%~q��Hs������f�j��Vq��F��Q��Z����EI�j�Z ����z1�	�G5�=�&#y��V��V��	�+��4�R�a��n����F;b����/�g牁¨��,&4�]�ӎ�    ��'�̚a��~!��G��`.\S����ofs�44	8{߈�>S�u=_�g�b�?��Q������EZ��S�
�q;$�ȝ8t
�E	i4�/�����V�bp��a�>_B�Q��k
�p�C����9;�����21�Q95�=t�!�6���\Ϥ��h����$2�@do�2�@z��;)h�Y��������jl�k��Q��=wvO�2���	�(��*rק������lmÖb�%g�\�0�c���9�6�]�Ԣ�����D%E�{&5!(��~c ����$&6���Q���-�2(�w��ͻ�8K"�0 3v��;�'���#�3A�����U{m���rV��I��e����� S�*�;�o&̓(����B�X�q_�⠾j����` \�A8H�p�D逊3��b�y���՜<oZY��;L�[!��8A�J��J�^x����$@)�yܖ< �C�N$ ���Z��_R=2z�҅�>��r�3�9e�*��i��V��e�tA2�U�M�]��b�	��=��CT֒X����KJ"פt)�	�F�2��:D`C�j���6�H�ປU�Ę�~6,o�n�h3W���{�2���Ϯ�>�P�/�紁*�v�f��Y�(Z�(�S�'�k��9��H��J�o�m��ą�%r�*����*$$B���th��qt����'\�P�L�dV��ڧ��i=.d���/��	5��w�v��c��(*�`L�4$W��t���2Q(��L���<�c�*Fe-w֋�i?Z�P]tV]H��:����=��gMA�+K��u�\����.�Z�=��{���U66c$�sj{�V�A�]�o*xSM�;p5�(,詭�ru�$k'��IUG�$nB��59W�|��q�ͫ��gH���Kjn�G�r8�lp+� ��poR�s���6J`'��$|�0��P��! ·���(9�8*6d�m��~_���xcFZ�A�Z7�np3��{���E�8-0)���c�Z҂���Ǩ[y�r[�jA�ޢ_X�u�иW�d R���JAI����|p������j�����̐�T|��1�J<�Z�M�P����y�{�D|����{L��Yr���74UYl$X`J.o뛫�3O4m�i3L�x�+���2}�e3���tL�뮫�Ոn� ��.|nC�qS�
;��g#r1)a:���� J�o!������d����6Cpu�����r�$��U�WK��;qM_��N�� ŭUZ�����҅�;s��ّB�2~�U��HqI��'��;�rE� ���z՘י }/�w���J�&�����s� �v�u��v7��U�Meu|Q���8���\p�����j�`$R^���r�/�O��=���xR>���{���m\?�&c���͙)1���[���W��ب�%ՒA8OȊ�VA�z���%���M�6�����E�Ѷe?Ug0�ወ�N'����p���;��bB3�(�惜 Kh��(��j�U7�{O
��b�	C��(D�|T�ɐr�9qU���r4�����Қ�@���}��q��L>��
��Y�oj��@�v+j���Ia����Hl�kJK�WnaW�L�n��jsb�zj~�kFf��;�͝.J{	�j�@�}��3`kqtcL	O�E�ND���ߠD(�,�R.4�
��7'w�#E�fюױ���9�qj�(o0dn�&��|�u'�(bXL�O����v\��Ġ0�Z�,ceZ�����vKBՈ��LK��cQ��1���v�H6���d-'��
]�2D���Ϥ-j;���9�?(�~l��sc<vs��O�r��&�k�f�}g�1Ǜ�X3�jS�r�Fk!)�sZ����Pd�@*x3�K�@�k\���й�|J��:de�������=������2�ĀJ��8�$�L���q�h���A����r�N
&w��M�b��X�@hS֜�O)���8M,B��-2:R%$҄�hc&ĩ��;7hO��/j@��Xa)� 3�A�*i�J��F��X����N}���#�a��"�y�LX���{-���"	�g��|�&8�>��Ee>9�=�����kxɨ��}!a��V�'��
��pz�D�`�b����]M��A�qcv������mx-�]#$�[�b�sǠ5x*��?�Fˮ����e��R0V�T�n~���o¨�)����4�0b(�~`H0:B�)���SY�7����[�PK\��-g�x���̒K(�T(d�����!���u.�T��hw> }�4�MZ�d�qrvZ�1</��#�Z}��#w��]Ȁ�a���m$��iY�K'�d�_��\��s��]/���!(h-Q#�<ϐP�?�����~7t�W��:�ٵ�|�U8���ɱ�)��F��ɊBf	d"�;|p�B�vϔ5�*�ok�B	�T�Ԫ@���uE{�X?�iG�Da�fj⚵	�	9
�������C��]�L�ݵ1�HG�O޶_h���;v��ݬ�b6��J0�/2ߛ9
�����̓��6]�f��yLbY�P�v�g���{�Yv?$�N&(DRK�Y�.P��]l��z閉�|�3��^����n����Cx�~�Q��"�ԙ�3����I�j����g+�< }g���H�jN����4�$��M%�RM.��8+q���|�=���C��ħ�)���Oc3c\ė��n+���������69W��$(n47�,��`���2�B��2��N����e�&�iF�/��(�_�1���4i�T�c$)�S՚�P��u#r�j��ȥ��yy���7�S���5aCӝ̾eD�Xa�֧�H��p�C�pV�	���;|hg��i�{��r��0��7K��;��Z�g.��^�+�~��+���9ǲ'�[�|�\��%�/�}�`F���2}��q�����z�3������`�ݑ�2P�,&r+��X��;��Qjn��;ZO���@ ��>������\����r5�yn[���B���` �$���	g�Z+vsϽDA������P������l$��#4�֐:����Q�n�c��7�Q�9����l5�F��jQ)��q���z�-<�f�0yҜ_��^��G%>�_�t[[M�FQ��c��	�9o��A�>vYǡ��M�fSx�;��s�5f�T �kõ �x����^uU�?���=(�	Q�Q����;l���X��	=4��c`5:!lo��Dv9���܌\.�q�~0��̭�
f�í�D�\&hiA�yFB/H%4E�w�Yá%��C2,H
�Ln4L��,�*��߿�Sյ0c[�g�~M��J�å�Ͳ��]�Pp�V��bj!4)�B���M�2�*��-ͱ��T?�Y�zA�1����rP����b�B�(A)L�1�Dx��ɠ ��*Q$���/-UZ��\�`��E3����kʇ[&�n/��q�Pʠ/��O�$+�M����u�QdI��f��#5��U܈E�ch������	������� ��̖�k ��\%_�Y����l���k����|�\Ne
���*-/�
]��9kN|�n3C��b�B8�,�D�Pt�x���]\�D��\0w��u;	  �R�`ta.�8p�::��He�A;�� ��!�=�|�e�F^M0��<-S􁥰�`q��,O$���iKέ.|��J�������I꒤�jnP-��o�@S_��k�668S���W)ʀ�`P2$e$|�dF��D�/�gٙy���-��I0��M��g��I2݁w}�Vt�Z����|>�,�G�	s ���9���g�Sp~##\^>�ǘ0�|>��*�/\6��0v7l��B�X2Ʋ��sY�\yՊg�����^�+�
3�5��f��6������7E�g~�6��o��S&L������J����K�	g�LcUt��ʐ�8�� <o�IN�,�^������C�tu�vE>�}KX)\&
9��I' O2�R&]��;�Na/��7�{Q#M=���Ax�G���mZ�?�(�5'-P�t��    	�d�����&� ���Y�xh����̩'��'�@\grQ�y�g�KWԢ�h�[� ��ߊ�!��|֩D��{aqGQd��[���95���L��2�)�Rb�Ԛ�@��M��j���\�L�b��$́�G���Ћ䌘��pRH6���Z�T��C���z��w����q'd�V����,�Õ#"g�q
 :�&�E�S�鉂l�)����]�sp4(�l�{�t� ��2�������7�1Հ�IO	��z�_��D�A���Ut�B$����jnB�9��/`�3�O��G�t9����#����]ü[<�����Ԅ��u��O@��v�;}n���߱�|��U��F2|�xҰKJ���j���x��Պf�����:�y�G��{�w�FT�<r֜f���o&|7�1�$-ZR㣠`N���C�Z�|�&D^R�+  �/�/���UK�8�WZ@YcE�]��۪2�gT�,�rW���}+�x�;��k����a0�M��nfuŒ�jA�9��:&U�	�0j|��2�ǻ�sVؖ��n��d_��ܡ����	b�]t��I�],9�줢fʃ���v��$���
HBgUQ���r�@���b��|6���pZ�J8*�ks����L�ﱋ�pq����$����	��6��h�8����c������vuR<��(�����%��ףP�&��7t'*�ra���e,��f��f?x/mƿx���4�O�ّ��X��dΠ�s�~�����(y'�Qg,)��r�T�#�r��n��[з�{�)��a��vܛ�	.��|��M֠ށN�;�2�p���)��r(��WU�c�Sc��*�,E����v�V[���oD�L�%���M>1�t�N��b��z ����V`t����fY��z6ړo�zC�A@O�(�_�4�b��@{BV��X2����8�v�4֑��>��ۛ)��酞�1n��dI�l�K���f�1���l�xJ��l�tzVT���0^+xG��W�>qP@th��{!�8�X��,�䒿3���*
�>rH���M8<�����+BD3���%:Ժ@��*�4�9�ӎ�rtx��f��@
A>e��]�@��j��
@D���8����a�K���s�`����-3aG�2����	^#�x��A0n�*�m֝�;�!HY���9IѵL�*��ӿ���|��	��͌
$�9C���^AT���W��zRH��,@��Q�
�Á;}ݤ��{9�6;�������5��H�EP^.]�,̍�	`�/0T�S�U�+�4�n���ຩg6ʾtA-=k������ ^�-_�^��y!�$�M,�^i�C����L����^ZMrt�U6������Q�M���X��W�S&}](����*5�s��n��g��[u�h��	��MMŕ�HL�L(�i�<w�y��}�Ԋ�c�}*�~��Ț�O��ċݥ�-+>���ݔ��s0{�;@����7+'~�j�MG{Q�vOW`d${�, ����5_t���&x�7T��ۻ`��REۆ?b�Sܷ�$yi���Y����o�a�X�O�`3�d>�N7�zݯ�=P�4�� <�����%�ob���V>�7+��Ń���B��5�-͸�XL⛺�lj7q��es�'�ZV)�Hbx~�f�C�L8�k�]T+�A�ftuTf ����y�*��m����MiC*F�6 �B�8~{�t>�E�MQ�Ɇ*�xf�T7Z�dhS_!�D\����u��V�0��FZ{&�7w�4)	*���zJW���,R��Cg��Ӌ�~�O�h����`��m�U�t��\����߄y��1n����3fi.饥~�*I�gɥzĸ�G���+g�����9���L�1�����jَ������i��$��z�ꖳ�TU��h
��ĸ�f����\�;�g�q�jؔ�n\r�(�2�1����#����C�?��ę�p�a�O�N�t�݇e=����/OZ7w7��r2ࣗ�S���H������6����_��w��s�*���j�w�,�|0�T�}���:%����dZ�lc�(�Ş��I�Ƀ��^�5u����:otL��MX;�פ?��L1?�E�>Ӕ{�=1��
���U�6��S�LR_�P��
�L�r����Ռ�/<�R ����mV�c'Z��V+� �I�;�<�b;�شB�����c��7��8:�7S)��Y��}��$B��a��~�ҠU����}	�,Ѵ�n�ս"ΥC�]#�熜|A<e��샨�1hЛ���eZ�'ཚ�d�)�xE���z1�G���
�2�P�S��D]��ݚ�wӖ���z���8�T����h������J��p��e���d;�&jf��h�����Lu�9=�[�Br�j��)�	���!5]�0L��¼H.ҿ6W�gnX�_��'�t�����O��
`_
vkZ���5���R�v�	
w���{��-6�}����)����p-;i�0�M=/?�s""Y��k�٣�Y&�P*��麗���V�^ȱV6�Y���F�m��U��*F��&&A|��񩷘qc�X��D�bo��~1��V]�H�Ґ�B-��C�-W@�M������*�t�"?2��� 
��'/�����:�+#b����͍�=g��K邜s�,��qS�����o�\Z;��ǰW/o�qbq˶�4S��8Ћ&���#L��P�)i�	�w��#��L0�P�4me741�oɿ�Y�ۭP�)CK(�;▥SD	�����o܄�����N���W�[6fuJ-��2���
��vs5�ZВ�	�e(c.c@��Qt���(�P����|]��y��,o������q3��h�EZn�U��ɦ��1%BBI}|��"c��[�}�ի̫�z�|��>�ׄ�'���PL��
Z�몞��#�&T>F(B�M��Fɧs�ƣټ�K=��E���Z�
a���
{���yM'cԝ��u�ԛa�j����P7�P�)<Vex�%��JZ���	�v=]����˓&��7t���]���Ў�|;����j� �h*���ȅ���p��$U�fu�c4J�+��J��"�G��WHeV��h�㮙M�o�/��1�M�:�K̼�Q볢y�L��(�eĬ)e0b�K���ь.�l1��/�3t��!�!YEۍ���3��|�5@\җ�v�lR�x��2Y��:M��I����?��D�h�E#Q0�{֠�L�������2�ʴ�DR�?�qY�0�ݔU�\��4� Ao���		f�ͼ�,>1[�9ixx3d�D��m
�x6�-A���V�]�7�%�	�^mb��4[Ei@xAT�\P���͒��l��Ɣ'A`�{���X6���v7��n<|�J�-�ѫ��I�Ҩ�gA8�V$��µ��"@���z�At5-Y�E^���9]t��	&1fl��3^K�. =�(���a��9L�lu����(��	6�͜3`p'A�|(�I�4�ʏ?�f���  ���e\͖y}r֮�m/�Z��z���NKҳS@Do.d��x���Y
 ���$h�py��s�����}��o���諎B�8��	v��ū�T*�� N�,U.p�	K�iﻓ�'#L�~Qd~.����1&v}U�9��*s��C���'١*2������sX�+2���J>
�J�[&�'�Z*�J��	��`��z_�/�%�b���0dg�cڃl�}��.U/\��Q����R�<cܠ��T�s(���X9��!�
Mh,2B6�',ɥ��0��]��7Ձ�\�)�ՠf����o�����J�0<cA%-$#s�OR���������c��2�{�)���}��Vu3(C��G;���)�����B���ʬ,}-O�㘣�;>G�Ï��e9�vUE4�Uo?_v���ƙ�'�s���	�DX&F�����!is���+:��(��	&��U1�b��#(+ ���s�S�*�dÖ���U����oܝ�m�^�T��I�LSf�c�z��A8��    L>�;He�������3Q������7��x3�/�Yh�j��j��x� ��7s*8VU$wm֜��;�Q!׉�>��xI��&)�.�ʹ�]o�@fq$D�f��4bxEw��_d�X��4�o�{� vL2����Z��:ȫ�i�j�����j�/s��|�Ϊ(������p3��U�Pg��a�T��;(!����(�;�SMsYA�����\�V���3�qW�+!XU؜2>A��u�E�ϼ}���nl���`�|Y6��Um�A��M[�8�p�RI��6!"<R��yBJy�5E�������'�(��� ����.�F�-ȣ$U�WI
��_�m�^�wa��3k��4���3m��PІ��	|H�W3�-S?�'��8*���ĐyVqآ�]���4J�����\V3��79>3��5�����m���Py���[=��7�����:l�8�˨�#��5�R�E�/fԑ���O�ºx�w}VF��QO� $�iwp�p�����Z��h�g~F.����0-ߠ�41w.�M�Xڄ�g���q�S��U�m�>H��}ӶUj�����!���tK�Oo��$�y.�p8�3M<��?�%ϕ��,_��c�7���j�A��)���{1�3�Ʈ�&��{���Rx����X����WKT1�ӄ�s}D��9�]ըk��6m���N��2�<�Vq�e� ��Oө�M�}��Ֆ�M������)�s5	ƍ�X�D.��erC;�W]�� ��7����2�N��i�Hx��.
�]�la����3����i��Ȱ֪Z�>�ye4ePp��y�����rK,x���&��28�_�v�pҹ����@�@��[���Ѫ�^V��(F��$���A��a�}Q��~A!yg���J?�o�z�&%�H#�[�'&5]UQ',�,Z�V�2��N,�2`��[��x��Py�7Ԋ�D�X�,�#���@/@t�>ް��Y�W������l�����[�e��&3�x����ؾ�vشZ���!>ֶ�q�F�v]yUK`P�?pn�QЂKM�����{T�Gn��3,u�y��:B�D�E�<��N�@�VErD�Rm�L։�K^d�Y��+U0<�'����n�����J?�f1���U�ٟ����}T3.�죫��ׂF6c�k)l䶛?��n�Г�� �L;��?+'0)Y���ٛK��w�a��J9Ų��ku�+cl݂K}��+�bgb^�s��񞦶I��Y1��Mg"�e�C
�.��tJ2��n}j��z��W�NH�
���"�����f/�av�[A���W��^Bp�oM%���C�[B!���VVŦ���h��γQ�%^�E�ք�������pA��m�$�� ׅ���[O׭��������З
��-���f��ϟ�,Ts
��Հ���p�b8�$��l0bL*�7�Be
���?v��*&K@����� g���6_V�f�~�	��͢u�2��z��7�y��.�"��(�E;� 	?Εz�I��	�XILL."���/���d��R6{Rkn��j�v&	�,�( ��\B�k>W�k��{�XT��X������	�>�ꂂu�9.�Xn��^������v@�B��u�t�)V�C�B�`�bsUĿ�
��!�r=H��Q3ȴt�ܣ9�t@S����|T��	��}�H�hj��`��'��)��9,�7ٶ�}�����?v
]V0��>��ƽ��蹕|Ҏ�-���sqjE�d�j*�C>w����,�ƍ�ʛ�ؠ�|���o>Z�P<P���]̧ĕ�>:�f��X������.��g�n�m�N�s�Hf���D͙����6sqeyBL�6�Ѹ��Ë�_����/�*�I`��~a��
�u5�?������ �`Ȭ��9��N��*u�3JS��OyOx.%c�<���W�R�w�4hQ<�+=���'[�E(�U��B�΄.�Z�:�Д�(ν���5a��L��\��zy�����Zo݌K4�K/�*��24��;'ԩ[�H�0!i�F�l������>�B�S|�+O�:jH��b#��J�x��Ma�u"MbƠ�����\������?�}��y�A��5ҫ���ld��b�
�R7�z/�J�e�HT���Ei�S�Df]�a���z<)�z�U:8$oxm\$��Dٛ"�6���X��|�_ڤ	�5����u�����hNF��c��=Tj��'��rQ-����х
��Ki�R0%�ٚ��S]���=i6�]��s�u�=�n�_XmQgnઽ���t�j��J&ǵ��T�������.;����,�U|80�_
]�K�.т���B9�5X�嶋�/ӭ��e|.��_���;��fv���f9I(f6�'�P��Q�Q�A�]��Fi��,V�^A~��f=���B���<�y�,+����)�w���Z4_ܼ���YT�E%BPC��91{���N������c�n�D���S�\�.�z��bz݉�
���]��!�](���RX͈�V�2�'�Z��
�zeV� ґ��ˮ~�y�*�e�8^��i(䥄�׭ �#��gZ����y�J��i�['�wh��{���@� �c���f�Aw�q)]z	�,*`������ڮt�~l��X#`��5���0Zo��4�=��c��cN+3΢��j�B��|�1�[�`�F���z�t�*ºPv]�ֆm%��6i�( �d�A����<H�$&�g�
����}u�*�T�Z�t�� d�o,�ቚ����7㒸��t��:��_`�)�pr%wmu󮿜�����@��� �.�|ݲ��h5sJؙ �X�~ϻ����Ǒ�VنQ7����U�^m
��o�TNg�����LN2������|�ѽʱnUi��El*o�H�d,��V���.ch�*�{o��.��K���"��&�ܪp�*���������V�	��.eIORO�p��lܪ��fH����xԅ�[WI��:Q�j��X�'ϛE�WJ"<�N
��ueݗXݤ-��Y�=����u�a�E �绌���h��I��[S+Mp� �)�wQ�J���U�碆b��T{�96���v�Ӕ��|u��k4H��<*?�]�/��ij2
�^��<���T!,͡:g,��$lnԤ�c�p٠�t9k�*��%D%�Y7>X�2e��42��TRL���[��Dǿ�k
}G\~1ݐ੢X;�Y�i�0ڦ״P�v�h%@�:CT�8�EJ\������ߖ�ӔE3�o,�-C��l*�IxqӘz?��\�C����mR_n}1:���A��}�jwprFUlQ:?��ր�,.��t�]{�Mэ��ƺ���g����{�5p��_7�d�e�^���h��z���j�<�S��Kf���Ɉ�	�������Ƃ:@{�{<�7�Wƥ�{���n�m�*�_�������Y�'yPj:�B*�d��D'd�V�1P������r��o+w�S׼�pL�����ic٭+��r�Ɠeλy�Z^2�5if��6,9�<+�U��ν���2�%U#�"����}�E�p��.��`��z	2ƼZ4��Y�2�1t�1��u0���E��U��~�?T�ye+���8��|]��7�HH2+�Y�e5�M�%8VǼ�T\�$X�r�&e_��p�X���|�AXeϲ�Ĩ�����$�b���jǩ��k��Ԙ䞯`��;qQ��M��`�&ͷ��>��`��ň���K��.2S��d�M������!�s{r>���XWm7.$�̒r|��jNWɣ.P(t�e����<�7Y[�
��`�xWM7���1� ���`/�X�Oa�Pw&��6Lze!N���kd�%�Ap�o��YB���~P�p8��Ԗ����.E��?I����2Siھ�lV�PI�s0��Na:�7�D�'ݸ2T5�!k�pW7�.������4ɗ�Z�+�ݘ�;��fM�G���?8d�߈�Mӽ��ⲑ#[ )K�0��	�z^��|K�5/K=�����&��ˎl��)��Em�Ϻ)���4��TG�    m�D�� ���Ho��5~�.�۝KJ��^.�-.�'|�\�hG1������13��[XJOMt4�'`3��z�p��]���,4M����*ZuHD�-5�;�u�BuDF�p��jϩ��쬏k	?f��"��圣4�����!���a,��ȓ7�G�s�v�:5�Q�,��g���:�De Zb`#;]���)�݀�;�9˜N�`T��IV��Z5���h�
cM����H�5:X��f	�F)d(����t�����JE}�$�Ed�M1�sPq�MҢT��8D� xc-7�W��S�
�ϊJ~�W���qU��-��[\�O�0��ۢ��Yzl�̥�A����`؁p%����U?��4�ܔ���z+��>/!S���|��U����uk+�dk['����~����}f�f
�r"D�&�;ԘQ�
�R�����2��GTw�)9�؝৉Rk��Ç���e��"b�����u����f����o�&J�EN/)��Ko�$�#,1�cc����cA���[�Q�*i:���T}��w@�uj�aP��t�ޡ��<at�i�u�t1�T�u�Jo=m������S��u#�>ҝǧ��������\��:�3���_���j��2�d�-n~
�?H��1Oh���:O~aҒz���6�=��ESJY@��05�
�e�}��Z��f����&0�p�G��[R���Qt��:��+�؍téߛ�f�I�TW��!\��m�K����I$��߀I� ��u\55�)L*[4
W���TH�太kYt�b�5S�+�5OF����v��n�T�wϱ)�M�]�[ڝ	*����jÚs:��.8�w���}��,�պr� �&�����ĺ�I�0q�"���kF$���ݕێ���oQ�_:�6��&��7#Cv�m�N�a/�����UQ1A��PP3L���8sJ*��9�N;���sQ�'|����aG�2��
���zS�Ф��~G���\��ģC*��Z��M�3�<?V���R��1� kU�� �M��Z4=��٬�x���f]W��Ï��l�$
�����Iѝ�I����IX��?�y*/)�I��ɊxU�巨�����,>��$�1�~=i���W\>2'�_T�q�8G�n'o�[Q�cq���W&�e�Ӭu�`��)6ȟ�����M�P9�_���&eO��r�O4v���O�îl�{��헳�����nG+V�*�=#	�x0�;J��E�Y���(��^�E��ga�Pe�3�㾡�����p;�7O��8�y��iLb����$H`~��Bo-_	�OZ�ca6j�29S�F�U�p�h+�z�ڣ�6�$Jo5K�Xl��bZ�K����m)"���u���m�j�&`g��B����b��g!%*h�Oy>СT����V��d/.�ݵߝQ��U���L �	@�λʫ|T�Ő����3�î�#6�ƺ���q0]�{���E������r
Ֆr���������♁T���R�G��$SΚ].ר ����ͫHZ��º�
��:I�Ͱ����ł�e�7@v	�+F�	el����E�}$n�U"�k@�_���8�*�y����8�gè0�V���A�.ջk��K�ZjB�JI!�ϿEۉ��[:�K7��������ۊg�T����ס�Y/����/�WV�.Mu�IY>�
�����ٳ�$f�̵h�n%��� ����5�.��9Ԋ�4��'DC]�'�3�%֊ʐWk�Cұ��TE֡ʡ�i]`�y��NXN�/�N�o��!�`L�"�Hڠ��t
g�N��_�׳
��%�GU�(_$����O��D�*�p0B	���&f
���ʉA�!�>�M��p���G�Q5�z&�>�> Kc���UU�pS�?�ZR�6*H(������A��Q��◕^P���]��R����_	΃��3c��n�8�i�@��-{3G�ri��a�Q���@�7؞���[E��϶�� %l ���&��F�Z���jɐ��=�ch�¢Օ�.���u�����ڏO`9��y��r���� �^Ӗ��ֺ��I3 �.i�����x������+�ʱ(�D��q��L� p�<)4�DAl1ܗA#�UqС�@I���f1n{F� ���J�;�`��rf���s��3�]�����\Q��^"�fV¥���ظ����6����6w	+�K+#�s�����)�wJQp㎑��<��I"�|O�LZ
W���D�0�j�L/N]з����/"���"v5�������{Ob0�C���q�a-����ڐ
��j1_|pz�a�����!-��}��%�Ranw��9ߵ�=�_:47�M+G�(5K�N'���:�� Je��4���g�{Sё�:���,t�p�Y9s���肵a�UJ��D��2�]��Lбh���i�T�1xr��8�^��EA���ș߹I�C�Yn%*���v˸&c��${&`�U���7�f��E���(s�ye��3�x��%I�&.��<�9��6�R�:��l&�'S-�L�+� �6�\�nl�k��p�4`����g�=��9"��HNy&e��)@�/>c]Xĥ�An��i��<Y�w����P����y����ξ�B���m�T��.h�X����~�?c��I�]����|���v�dE� RUmeT�o�N�HH:�" ��}�9�q-3�7~��߭�T��l�y��c�e���Ĕ�k
~�qnԅpe�� 7Q�˯��	A�ɏ�X�����JOtu�ׄ��&u�d萜x͹�J>��|��*K�"�;7�~y��|Y����
E����C�W�9kP�t����~��&����+�awӨ��S�~fZ��~�����p�q�N�c[Wc�nL�?�S���ٗ�~���n&ə1f�E��QHo�?V/��jX��3&?aZ�w��*�pi�(|˽=�)��#��.�Ava���Q��(�D<+�5/�����j�;�Qh��MeB:�=]=0����:�a,��t�}oi\:l�0{�{���G(��D^�\����P�d4��!ڣ�M�1?��ry�oӁN�ROO��Y]MH�o���{�S�ȝ�3S�����-|7"X�Pe�H�A �$j����b ��"v����:� ���'K;�wW�ۉ8n]�ݻ�B"}S��%��	�A�	�����0�0�]]��7�o��=#���#�҄���2�H݇!h� +��V��jr�]�j�lB�|��{�4��)���i�j|���WU	*ŗYK��c�i&!�1�e��x{��b�sd�0t]���EX�dS��L��QY�ܾ��jI�9�bt3�_!�I�S�����86�³�_���`�4+�N�j��w��.A5��xo.AL�4,��A-�\�w��ӨqfZ*��*��L,&���W�>�oBP}Sw�;j��8w�18�Ae�S�c̒/
A�l����W����wĠ��
Jke�4�Y%����!�L�;{	�6z�C��8N�b�Rr��w��4��n�N�w����y��jr��@nB�}S�w33r���̼qHH�8�;��CE�_�y����%���dV�I=#�β�dɶGXɊ�>2 	�q0���:g���|*�<���*��>��� ���ҹӓ�iC��)=��3�h}�鲕�����2&���B��d4�W�ͳ:B�,z �L��Y�cq��I���L�@B%eG���h�p8)���ƿ)Ps�>Z7�<����b�6㩀g�_�	 U�%ӆ&5��W���թ��H��i��Kʾ��.8��;�Yja\��M�W���E�d`AV���k�0������b�ɓ��3���b#��������"���I�ibZ2����c'�^7Q���X��X=���׳z��l���2����Ȓ�I+��_G�p���Ym�� �ݮL����n��N�#��8]E/�P�w�r��?:M�9�IUu�����/=cީ4�_P��]���0S��DLِ���{{>Y9RV#Z��ye;	�    /�]:�O��xN}�R�R�a�z�	�^�i�AL���o�v�V�S��	Ϫ�>@���MO ��K�vn(�ҿ��DU�B9����< �[$�}��^��a���bp�?]]���zH��'IÆ�9��6���{����s�V�V�3.NjI����%Ŷ�x���IY"�irk�'Φ���g���W���{J�B��w�Z���ͅ`����3����~�Y�Q#�D� g�F[.��8Vnx�J��|,X�v,�ȕi���'��|�+������z{�l�!��n�Bw�����8(@��6�pR�}�ޙmCg�^,�z���,7�5�<�w�	e��ٔ�{�#S�hȞN��=ζ�;Qb��t����6��Y���@-gRщL�'o�L�)9��r.d�,;DJ\_A=8���пm�j'�`�"J�WU�[���qv`�ț9�搴��|���Z>�K6p!Ռztdq̑*.�I�Rbhrԓ:r�����#Cǳ�i���u�U��Uƌ0T��K�e��t:Dmi�9q����/g�kj�I'�;�.3���9O�T���X+Pb���F�#Y�	����mC��w˜١��Sٯ突LPPĢ,�ϗ��go���Kט���*}e�c�h���ʷ~C�\�0"�4�5#���MSÝ��6t[�
 ���LDt�稕�2v��x�d+T�� Gp^�}��:'��f���{��{�8�W�(_��-� ��&k!���e�"V�X���3bAZ�FM8�aU回|�(aԒq$�ݏ�)��邹�rna��e�>K�*���)g^!�ݒL|X��.|�#{�tn�'���u�/����4����9z�=T�-�ꏥ<m�5����<9�uJJ���~���wZ���7��������l*R1'L�W1������`͚�rzU�Q�+���҆�Ջ�q�y��D����O��.�L �~N�zô�	)��I0	M8���)l�Y�4�J�Q��$���[�ae��_Z��̮���;�p��b���4,�ܔ��  c�
va�l��$	/�N��"� *�v�kS��Q�&��yGO˂���lM�Q�l$�bl\�!�$�J��"W"E�8��}�_���>���=�$Yʁ�C�,���+�ފ��k>
�n&t9��F������lJ��i,JaE�f=�8���4��c�z�4wS�Ţ�X_E@�ojk�ŞD�������(x���3�u�0%V]� [������J�6uwJ�
!�x�j[�T��z�Ԅ� 'lU���P���I�,�¢�QI�<A��E�nw&[JSG��@��2��"���_�돦�B���������ZGӞ���ͺ{,=��p�h��4��}26�������ȷ@����E���NS�N�O���O��� ���0�a��Xi��WΓ�P%R��[���jp �k��aym��Y��e� ��*�m5m��Mh���Jg���Cv�t~�O��$��u�{�*���-��y���8׭�[�T]"��Y&+7݈0�9y�*���x ���i'�����dM�H@bl-":���Mdde΅E�x��rΑ�����cK�Dc���Ta?����[��H���N�ĂR�5�56�}��ꙗcFH���ۧ�u�~h}� ��R�P���~��f��+�oĪ��B�P	�ei������.��si��ElP�e�;!���"����:�w*�E��i�4��'qs��A��R�J;���M=�y���j�J�o ��e;�Z. #�Vs�ʬ�/��9+˧�9��EϏ�K���
�v����ɪ��x�o*�!�T�ā���z}ЄF��T\�*dZ���(W�۔�zq�Ҙ�֛R6�S0���8}�?y��L�gǍ�H}�K��i�>erQ��������8L��k�jZ�p[���i�U�}z^������Y:%�gi�y�ˬ_�\/�F�f��1āׂMӹ�����Dn��4�`*��>~�^ߌ�c�we!�jH����LP�s(|a��>��Ɩ��}I=�z�ކ�%���b`#.h��o�E�,��s^q.ˊR��$9��?]7>gQ�J$���4��e���XoJ]�1v�=I�ڮ�;2�6�@mS�Ef�syN��B�tY-�K����z�T��]�:�,��#Ս� Mwp��x橝�&J�ݙq�\|B�&�t����D����U׭7�mh�ZZ+�(|���vJ��֜r�3<�.���1�5�} ��J�b�N1SWc�p�@�r��K%��8��\�]M�����N�p�+MM�t�����s��d��%Rq�NW(og��y���;�uJ�д%��|��k.-]�b�E���MK�A �����4OjYY�O$��s_1<��������]m��*�4=��ii������µ4}y�٣�X�f(� �TD�o|��'�<ˇ�mj\�ޥW��Ƕ�����1�y�),���I��p!#�I�U�"��3nC#Ւ�N��bC5��+��k~:���ԅ�����T@TN��%�����iI���5�:�6T�&^韠2ߎ0��1�7���?ˋ��V����h���:��eߊz�]S�Zכ�MJک�؟E@��RUS���}���:�g麅	� e�W�6@bL�3�-�S��h;��`渋�N�By6��{��,z��R^t�;ڥ\���+
�oߦ� ��Ӵ'N5<੒�T��ʿ�����J����8��`�`��i���+FN��?����W����G-�;��By4� �J��N��ǙX�$[�E�zX��������:nE�xG_�"�#C5#��|p,�ح�L?�7&��Ӓ�6D�l�ug��T�C�Jb6�ҰVP���Η�f_nh��ꍱY?������߾����K�4~�]D�����T�6��U���"�F6�!L��1���Sxyg��ːMF��E+�t%��N�i�6H@İ�~s?��C��nwQ(�IuN���?<��}��r�6w~���t�ʑ8��ߜ|�J�����R��(a��"�	�mZ��#��H����47 8 u�Qӕ�h���	�TA	�`yO��v���+z��B��=8��'�}G��n�#��BC�Q,���!���ߋm�͟�cŻ���Ȯ���������l�������GB��q4!��puǃT!��"�C�Di� r�]���vVFp��E��Q�ɇ_���&S��L�M}��R��vc��t;?˲��A��p�/�7�
��@gM�SѲ
�<���Đ(J������dDӷ���9�%4�g�����nc��+��H�J��%�M�=j$�U̢gy�J=�f��̔M՝�a$��b&������;˅�;��L�O�~������O��|�)��<S�Eɹ��+��Gnh����:��c�U/:!�m��!6�g(�	Rk�/:D1���Ȥ���\��tP�n$�� ��靯~�b���r��F�/��#9:�8�#Z�BK��y��R-άuA����)����;��M1��9�[���{���-k��4�%�"��=���5�@�����7����������r���(ČĞ5��lև�]h�A�J�XRл���荣9!��{6[�Dj��%��6JD"�)S�e���W$#�&��q+OoH����;}��Z�]�Múկ�YGRC��y�
�*>���<N�g4�������$���!jT$^w7	��Rlz?��ES&�4�d��~i�8s'���~�,p�So�h�'x�������)�tL�
F~������B��X�~��{EK�1��Cⷻ�q�a����6��8�/�M{�w��0<wc�Q��_�r;�P�C9퉻�+f9�Tw�P��*��N�j�#�
��y��
<f�T����uwm��z��@Բ���C����W�����k�����l����(���?:�ac/Վ4Pi�C��<��w�չ><Q��p;���څ ����T��f�i=5=������L;��Bײ�\io�	ά#    ͝.�.���"�oƘ��Rj�<���A< G�� �!�6 ��S����z����C3�o�+��e)͖��'��H}?KҌ��J�K���w�����DU��	�QS��J}c�N�U#����da�n��O�?��@jv�T�Ig`Z��ZKI@���6w|�}h	����J0�N_��.�hr�V�g-���~��Z��猍��:ih�8t|��j���flW�T�|�d�)�+?��·��R�x�Tc�w�6tɵ��l�a�(��2�o��c��|!�|�4ȁWk��8?��ә�'��7Ua8�w ��V��u����{��;�,���j���A� ǫ1�[-?���WS��sϤ�8VUꔟ�֌��|D�C��\Ҏ��;�[�ę�ң=( t��Q����HQZ�@]i.�� �Sh���'�h�jl�����M�W��--�bb=���ϊ˅9e��T�s����c��w+X������4\`����
]�����x�4���T<^��E�[(���G�U�u�cMH��FM����L?p���1Xj��N�*�W�]s�_bSnG��Kr<��"3�ûC�A'0�1nX%�03�O��#-VI��U��}b�!�2�:��	kz�TgӋ��L�G�}>Gͅ�� ��W�x��t�n���;�O��'�<���t&�5��p��`�k��~�P�������}D?U�f��d�,�V���C(J��K��)��m�w$E%o���,:ؗ�"j\,*t��P���RX!���a�0�BO���l�0$��`<�3��׿�>h���<���<��ư�8�Kzѐ�6b�_<6�:_���vR"�F�.;̣Xg�ZϽ���!VxX�$�[��^��w �J]sGV��$c��^-��m�����i�@�;ɽ�H5!d���^��9��uMx�П�M�A)�"�;:���T����wh����.T�ݩ#�P�Q�o,�4�Dq�1�TDJj�F�@_����M�>SBw0l+~']y�õ��P���O�R��3�@~x�'̩�Ⱊ���B�UP�_�P�`;��>��]�s��uL2дn�7����
�!�U{�s^ɫ��!}��[���ue��罕�3��l{�ȸ��	�;'��bS��x-L�"�$���A�ś��E��@�5���}DnҔ.��X���3ME9�X��i��'Y�6
����l���=�|ҋs�=\��	�2╱
�5�f��X�+�W$�4*>	�����WD`:���(S?���~��vK�i��9�B�>ʎWrF�$����bŸ^,j�@O|͚)�"D�!�4jg��J/�49�>|�&3)����.Au�:�����_R+@`\ �MLE[Gj`pw�M���-��������YL�}Vm,-H�ޠ8 ����T˞��#��٩����� =Ow�K�ہNFra~�9�@b���y�*3�t�l�!�4n��;~�!��P�XM�	Zלw?��1�W��mh�A�8,d7.��|�b!�o�4�]�*��Yg�#a�f�����X�!YV0��ǀxcӖ�Y��C�.>BW0�3|��X:$˾ѿxi����ɼ]N�Z ,�o�v����6�܂T�7��Jl�<,7��E=�"T���+{�d�#e	���m�;:�!4��ޘK�>��9 w�6)�5�G2������Ы�:��!H����N�0*�ϖf!����06_��%��:ϕ@�i�8�vE,[�l��h�FS�;��!��b
���b��2?�����`��-�1�x�=��K%�J��}�q��s*�F\m�y/�
K%��;�{���g��M���OR�<VMK�1x!��``�E*}v�L98u���^ng�V%����F�mbꆡ�pP�Ϫ�-� ��LY$0�|���~Y8�l��)�ז��U��;��H��;�F�ī�q8`�P�Ꞿ_$������d���,�Cz�oT_DD�H7>���37o��i.(_C���]fʫ7C�*U�$�{��f��f�&�7`Ķ~�)m�0o��1�*#Q�x���R��eԞ��E���rP�85�iR��>��d�~AA�˜8�-��j*|�n�e�N�|����,$�n�$�soܬ���y��@ذ4��0�7ޡ�+:�`��M�:��u0-o��`��ߕ-��]�}S����cu&1pS*|����"�J9ROO�Z��1�cW�e�4�A/�6���&��ر@�A����@ˬ�2���TP^,L�]���@�K�T�=X<3���q�XIG�����D�{/A��ǾҨR�����a��d�j���w��,	���5^���A�=I��(L�x�I����Ù��6�Uj��/I{���7��Yg�6��3ǻ���ݳ���H<�T�m���mz�q�4$��%81��Gϋ-4�E�*q^I[�R�>.�P<Ґ���]�&1ZT��W��y#N��C�|��t�i��;Ci(ve`�I��f:��~�\8�v$]�ZQbA�&*/��
	P�г������_i��J�ME�iˁ��@� � 	,��/�&���ܲ�F.�?���I��s%l�"�{���T�$l�� chKFjKޯ�]�$�,�5�*,��1)�4��+�t$������ʨ��)��G�:>�p^���YbG���]|�;�-.�,B�j�Q5�#k(�.bmخu��vL��F��<R|�O]+���St��I���� H��;���a$�tG*���Z����X#����.�/V������\���׈_M\��x����;x��;��v��z��Ď�Μ����o�VA�S`������o'��KH�����џ&�\Ș �V]o\�X�1m�L��H��k���r�꜑�ZRh|2wUf2�aa�(�����\���	�eT~{��Ť�=#cQ��։?hjX��7"�SV8�,�D�cq-�94?�M��uB.N�DA�X�X��FZ�;���i@��Os���~e
�7���Cj��F�	d�0�M��g�ÕJ�b_�.��5pr�1�9#�>x���u���<��T<	�
�t�0�ǂ,w�N(���s�X��Cئ�H��{�)�~�c��k;��1��Xy8���,��8�=�@�@	#�즠��[��B��l�N4����	�P~�zk:B�x��̹MO,�Mj���]a
�D�'���h	XѬZ���O������P��u��3���_1�N��c�k�yS6��}1��G��ؖqz�-�F�5�2�k��)4�SWI�1���6�F�r���2c>?(���P07�J���q{�OAX�B9dέ/�h�~5�����-Ŕ
���)���0�n�����o��a��ƩO�+��3��(�^�����%)y�����c��b��ˣ��O���z=RH�6Y�τs�mڕ$��_S��J,�����]y:���	r��?��+��N����ϕ�F����@�W?�����ɊS�5���p���f�l,3���MROMHVR�0��B����˕g0��&զ��~�4��݉���hC��9e.�+Ч�@�ѧCoZ_=M�:"o$o�T�&��s��,t�����굘���T=0�� ��K�� �2]8��@~��M6��{�0���X	�EP:xQ�.{BC6��߶�����i�`�#Y&#YLh�/Y>��Uh���
�|vS����݀nAY(�c��V|���&ÞN��\N�1Oyn(�pl�Ȃ&���͆UvF���$`2/E���yƁ�L��}׭�_y$�G���A�AX�!�u!R'����7IL
H.+�}^�{_,��l�靣	~K:�~ۯ���sϸ��J�;NM���ĵ<�1��6��N8�AJB �N�&X-��`�J|���.�1/��g_R����/I�a�Pz�\��R�i/���i�>mn ���07=��Ķ�j�лk���rC�h1ݧ�9W�y��b�	;�­����P��7{O���$��Q5�`x�T;м�L����A�H�,XO���`��5]�J��UK
��g�Ϫ�P��ݤl�}�M.t.Eל-)91T
^��	�|�X��N-    �!����3�s�=��}1��	nﱶ�P$&��@��+���ط��]o ��q���
�@�0�:ciqu���g)�c��x�0[�{]���:Z�Gi\�������Co���TzD�������;�����j7�����̜Yj��YB�P\b�(�����������B��	���N����,b�ǅ�T�$�O���.�d |�DG�`m�� 1:�vӽæ�$}kN�`3\��aSNs����1\%ػD�q�\�x`�~�'�y��ӱ���*��$HA���QI�1��\�r���6*Q���?J�e���zZgD��P�,����ڠ��/,{&�\�I�b	�����l*��o����⼱}���hl�wB_�>��WTd�((�x�H�GC����[k��X�_p�H�j�n�Oe�>���㛿��O~R3�<����%��7�H��@��6��~t�q�����nmѫa"�p�8LU�οO�%<����A�#�Tτ\I�󺱈��D�0��2�6���J_������)�#>����;NY�<�ԏ9xDҍw�Z�������A���/�!���Cp��ZjKi�=�I���P3����OԪ�'J���^!(�ǡ� �Wi�͗D^<۱2H?X_}�Q^2�j��#�!�I��6��F?#|��i\��,��i,��Q�X7���9����B�u�)��<�����,d�q^�m�+��/� �������(>���i�$ l�������5�%�+�Y" 
V����z��#��d��8�E=�
�٣��{��=��A����.�i��G�f"�I���t��5'�:�!��vቍf�����}��G��N�2H��%Qr[���D��H��� R��UN_�[��lD]��m��.��E��2V9� �8j�������@�M�<����2������5D��M$�z ��~3�J�e/+i>�N�3��wf@鑇��V���Q�$�x�����eF�Y��DC�e�dJ'�q����Oh�i3�`�,IB��>|���ƛ?�7�4?�:�Nc��7Ip�㉈�: �U��2�n���By�S4f��Ȋ��;.��Ȅ�r���ղ��4��J.,|z��bC�xф�F����˃�	ii����䖗X�2_�,��0B����H=L��jh�+�:�u_Zx��RѐvY�R�f��B�V���k�\��pͅ �n]R�`A���m*]����7"S=���j�:T� �ߤ~B%
';�ԘD��i�ʖ?J�ӱm׋�:�1t�K1��BUԻ�%�|�#�F������E����y~�s�'Vuѡب�JHk��w�����E��bi��bpK�4*��E$%��٬��_<�����(���ΑڢtS���Kb1:d�UI�)��cVde?�F������|>�vO\_�P�����������,�i���?G9����ܩ&CGTOU8eLF�X�y��x��X�d�P�����͌�z��N&M���Pa<ӥa�Fv]9�B�G�>v�(H�F��ji�%N�t�
��V�*<v�;��2T���/��yR>�(��u��������Q�O�,N�Gu�	$G�7����&��������Q��i��2+R[0���W"E<����T#ɧ������bZ�T��]�/��*�}6���X��pz�ɜ�Q��UaȰLS�~���a�Ԡ�G|&8�<���ޏ��THqs.� �=��'A�����6� �m%����/3W_�1�4��v���O�s�:�?��]wV%��ۿ2��JP���~ �[S"��U���1�"C�J�����͸�Lr���� ������������}9�<���r�SK8�Y���<�������x.@�I$"��i�t�]���Ā�1v��o�$��8��ضU$�@�p�n�wb6O���]�
gzX{!V9�%�c�r~���"A�{gꓓy�'|�l.���*II���1s�J�*���.ȍ�ӌ�˖F}��$����s�*�3h��M�F����_�áy�!zG��4Jup�O�x\F�z�3��Iw '/����b.�*��55�}��U�А�N���w*�������8�y4�`�+ߙo5���\��Z\���MC��ԓ�me�r4�t8	LB=�%�O}$/�� ���(tw�+gH�ݝFhJ�t�Kn�h"͝_;`SN�B�R22�'O�Йg��T�ٯi��ӯï�y�9\z�o�b��4uA��V�iv ������`P��&}���q顳���E�Bc�,��;]M�wn�P�o�J�31b��Z��iU��З����|��{$��3D�!f⫲�T����-���A�'< ����AGz�
7r :�2��y�j��KȰK��?��zbH����[ځ�\�~���:h϶��L{����9��!��c��b7� ��3�/O�:]	��zUX��L���C�2�	�$!�����g�Y^��j��[��	y����S�wg��G:��
&ϯ��Zә_�4��P,����w۬�`�$�.c,�u"��7�q+L��Y:On<|<z5�K_����|���%>��O�u�8�aA=���<z�'�4O��T�몊&t�>�.���Z�8��L�o��Z�I�k/���M�X�d�ϩvЬ� 4SL�5�����*(�;�B���hk�Om��3�����VϯT�a�-c*v�����~>P{��?�Q�P��ÿq�Z��\nϯ�����X�����Et�X5jZ��f=v�	}@Ә���P��[U�$�ERU���_>��(�����ޮ⎥����أ���!�8t�/�'x&��`�oښ�!�/���#�-�[tC� ���k�	]E�V���B��3��l�>H�T�j�X)���e-�d m	�<���T�C)�[�y�"�*�&�	����,IC�=iLmA&Bp&Jdi����u��5�`*1w� `����E�J��q��[�����^�(�.6i�@�>��3-`�7��%o{��І�����E�R4�b�[�N+�|ٶ� ^@�d��,�6gg��A_9!��7^zAXC��X%.说������`'� m�=��aBd
T�Vu���dCO@sU��W�� ,i��)��B�]��sG�<o�H� CU��"o�Z�GN�u�݋qϾ߰62����T#(O���s��a�������Cp_W�v���	y�m3��A%���'��ܗ��+Ðr-Xx%�{#�3�_����V��4��D�۬��,�5�M��ۦ����:)zc��H3��n����PC�A� 6{g<s����F���!�Ͽ��d2d�vT.�k�6���߃Լn��u:<�'���E�
��+ϭ�L����c��n���w��vS1�ӈb��pE�,-�Ǭ��(�}W»3�wq���>���4���Y4'F�ߕ+qAߊ���̫&5s�m	��W����7�S�;X�?�tĸ$� �K?TK�Q�������T�3�<�hcQ��8�_�_P_���ҺD��O'<�)Iv0�(�JMJtX+�S�V!���b�m���U~=�ZD�J���*Z���j؎�ѐF߶ۊ�Z*�&��[|2��2=��<���2�5���ǰ��o����Ԟ�	th��.��&}0��H��c������t�Ýj0�Ƿ��cs���b6q���_qṗ�d���ʿ���H�T�����4̎��"�����?���1��_x�A=�;�d�ePvz��E�I����z��7oc�!���z���._zZ����	���v��\"��a��](jTR]�g��ͤ#�ú�ϣ=�~��]����.�a�p�Y ��	���[Ʌ����*�0*�Z~��l\�����P���Wǚ�W�3ɟ�r�s�0*P�$���ƣ(�+��D^_�ad�\呜�_��v�~���T�>�x}$8SK�w��!ʝr4�tG'��Y�>U\[Xb53B�,��+S��|��yC���    �K�,���UW_\WQ�h��mL�Lt��U��5������$#(@�E�3����nC�{K�I�,o51��0sY�;U���\�^(c䤔c��/���bAe� �@�,&����3f�� �e x�Y�R��^>�h����o��ՓF|L��n:��)댌6����u7|�N0u�e)�3���x�t���#F��� w����fn�KI�Z�ô"O6Fdx��<O���
�h�5���n�y�m���ז�����v��	+�8yFR�on�[+�D�r&%  !�e��,<���	B�P�Ϳ��E�`����·�v
��+dM�S��A�mWW��P��e������%�<�Sͻ��bD�`�/L��ZV��i�`g�����|���iN<1�w���r�sK	��T�T� !b/%0P�A]�v�]_���r���C)V�0ne�u_i���Wq���PE-ಲ�܄/�D��h�'C���I/�(���~�����1���~:U�J������o�A�D=��<p
��M�h�N���c	�m���|��r�,|@��=�2�AU�Śqf=�	���b^�f��|DB;C�:��W��[>�-����'a�p��@fQ�X(}����L`�7�u[�c�^��h�$�1�P���D��`V@d�@2�#���4�
�ec���.Z���pXC��t�_|����`=�Q�.g�ԻA�/%�bC`wOYo�D�{;��+���IS��U�د/�B�7atm?��G^g1&d����s�6<7���J��OH��>o��3[�/p����,�p��F>�X��k(���޼��$Q��:w��!�MW�gb�b���μ�G%=��� w6�ح�\����{��k����P5�����=-�]��qҀ�o� �	����<�d38l䝤����N��n��*}xjw���k�>��g���?^]*G�?OqZ�}��	�f�Y�u2݄�J,ܲ��a��g�ty���"���BZD�<�E�ab:��^)�݉'�G��笻^�2���G�K�t+��:�q�
l ���@�_�}d)� S��[�C��L%���Xm���k:pғ����,�%�䈤�M}�D
��n�\%äN���G;����Ds�X�l�5��3�)���TzKhŀ��heN���:}.;����-���30��7�:�m~X�I"Z�����(m`ZM���6���=�q���,�j����e���O���g��s,B��/����ɪ�W}�����:�i��3�?�'�<>��:�����G�J���󱪑c���lh��.�>�e��(B� ß��<k������g���+X��27�Ѐ�G@Pb�$ʙO�\`�+���9ȫ�?�OG�Y�����C₀�7�	��Y�4E6�j Sga\xFpZ�H��6���a]ub��~[�8�����\E�	��L�W<���F�m���v�C+�*�O� �OM/�]���.�U	� �����;˰@$4��4��4h�T���K��n��Aa�D[��烷z>��7Q��2�AۅS��Uc������������HT.,kgO>���$�5䑀���U�����8�_������W���h��;=����~S�ysC/ӷ{��) �&�)56#)��f9 �rs�j�Xq�	�L^'u�h]<AW�*!iH��9����.��]3�cO��f���۞�P�"��>�}�g�����7\.��� 	�'���|���������!Z�o'��`b�ѐ!�bFm��N-H�F��۪�����T=���mq����)���!�yT�ף[k\�Ϻ �-���7R��l�� �0y`✊���Iɟ�r��d58�(X7�5�?rV����Tm،;;�����WDHk�]�������6��=���C�8�֒֕��d9���.��l(�y����j4���)���=Ț�,>rĈ1%�e���f�HI���A�����[��X2�:B���7H'�[�QhC�vۓ;@�6����p��,~��c���@58���.|���z��{��q7�1�Х���zi:m]��Ԟq�-��td��}�b�Ǖ�ʆ@1�c3TM-W��P�S6�g�J����Ek����_з��0�i��SG�*tR-q��n�I>���.I�0.'��_�S���#�!�m�~z'B�!�G��khh�?����tSm(�r$LW����XHЦxV�ؼ�j9���1r~�i�s��~�62b˪�7Ued�E��žh��\�����b�z����γ)�G�9oeO�Н	h��O�cH�C��=�J��n)c�|��R��"��mE��L�un�E'��zv�%��TY6t8�~�� *�6bmy���>%�J�w���oZ�Ǐ騫�Uf}2�ۡ�t�J;�ڲ��l�]z�ܜ�>��eTE-:5��N'V#Dm�JqV;�奈$��!�����_�����/���=Z�ˮW~�bv���1��ԁ�_���2��D�g�5�/U��f��m�%Α3J��P<*3��qC{#6tk����o�g2;���h�vK���
����6t���7ᑉ�L)졠����^`V��b%Yd*�K����J�6h߅�yF�V}��� ���C����wM�U���+���\��8�Dg+W���)<�޹�����d m�l�82B�w;��,4r�0{��Y���.�D�-�&�&�LHұ}P�_KA��Z��"�^����2�e�!H4�����F\��ڬ�t�=�AH�n��r�lf�ַ`�]M���[,d�-����*O�(��/�Ú$�N�t��Z�wx����LKһ��2��y�����d�[�F_M��m�x�~l�Tq�A����2�y���fvx��}���~����J��yX+NJ&��{�u�|&E
\>�x+g�E����V�!��>�*�;��cM�]m��̚6$~��TQ�ÕN'�����G;�K��=�e���d��H��W���,)��U���$X���WL�];*���oY�Ի�Ȇ��L�]�q��~����T�B���^�ڧqS��>�]i���F�"3����ȁe�T�����`!�
�*$+�n�%}X����[%��H>(�0jO=�D��N|a/��H[�G��H�6D��.Z�K���u�׶\eq�_B�bO� W�[��ҵ�~ދ��!�1��w�Ķ�*+\]!�Vv:���,���AQ�� ��3	'����蚳 �Ƭ�i}�B��q[��$!BV����L%�i<q��\IKf]6��4�����52
����]��g��<G�w�{���Μ!pH—�>��[��G2�m�]�!ͻ�*2S��^7K+�傾_|�~�k(}��!(���x϶�������H�׫&�jg�uB���zxS.�z����@����5�G�M�oc���AQ��P��3��Z�
U�V�H��p��z����|ک�;g��t�����f��9%�&�o>P���@!�>Y@q�y'H�XE�Xǖp�X.���f��M>�u���gaW)��:�=���#*�H'�pg(�۱���o�&��ݓ#�K�|L*i@���N*WK�?��.K�2��[V�J0�g�;���`�6#4�^�f��X`�
�O�R�I}|��TB�y/@���>x���q�8R�t�J���8ħ��d������)c���%���q�b�]�k�އ�3@Tg��"~�9���
�ӇN���U5z��RQ�i��
�_��:ȹ�.�+��nۤR��)8Ĥ�#5b����ܒBX�������G|n�X2�.h~S�L���%U�;�%�f��=w��EC.�	�0h���rZ��5Gإ����q�-�Fk�1�{w"{t!�.��B�E h^�͵(�&q�%�����Z ����!�ػ>>���x���7G���˼Z�$H�mdU�҇=������*��v��;�0nR�jg�N���b�����i���^����L�X3�*�PF����5������*��j3' 2�<F��E��"<hxG���U    �.����m�#-�&uc����qM��z�L�Mo��ď��gL;�����]���>�rf[Жg&����~��Ku\�_�~Q]�.�,��@T,@��L��������;O{=���-ꥣ3OV�Z�b��7̹���0-ưOu�MS���;;P|��|l6��6�_(��J�8�Ӫ����n>ٙ"�:��"��Ydj'z���"t��"X!�*$��Γ<�O����2�9�Ǉ� ⴄ�i��f�<rzH���N�.^��-�����cD�ut�v���#��1(�����O~��NV����t0)x/�iQ�,�cn@s`]���H�B���Aw�6�������� [1�Gbi!i�nZ�z�qDg)�(M�"��a}9"�۩�D�.�l�>5D�"��/�5-�H�y�8@�(s�O��G�(��$���Bn�����2>�K��w�Cs~yU4"�"�H봡j�~�����V^7���|��/��͚�~_���Zm�|�eMyXuqf|�H"Y=��hRsAԍ���E�W�2K�\:����)���������9�Yv-T���74:tE��w�g=U�8�+�C*z;uV��4��2C�L�^��0.$�%�(_���F�*&�!����Q�S�,Z�H���Q���H��~�49[Y��\���ή����&��S0�P�y���i����E����bֱ�Ʌ[L���_cVf���8-�����۞#���@!�N�1�HI�^����s��2�L�{e|)ɠ1�U�=��w��T�R�Q�'�el��EuHo�����O��]����0 �%�pk��m�	�����
���`-b��;3�P����6�<�ִ�Ҩu�M<�ry�U���4�8J�K�����D�:���d/|�S��I�<U�\|	L�׵���G�`��?�o���	�XIhG�"ˉ�X�n����_��D�v"� ������?,�	� (|!�ɾ�r"� S(� K38-��lʹ��p��7��̈́��2�Y��ҽqK�xk��KzF�bp1�����j�Xt�L��N�I?I_�M� �~��l*E�_�T�0��-��&_cW
�a�Ε��h{�G��`w�y�+O��Y#��ߥg�
� ��.��;�e&Z��7��Ě�V"��{�@B��P㖪�~��s�B�z��+�y���)�wg�u���_�Eb^�鵟��mϬ�yc1��d�זY�\21��SD����W�1�]��- +Æ�����;܅�u�+gz�m	�T�T��pĪoD0^�!�6�A��s�v�l�#�Q�r���=�f�RF�Pr�F����$�}��ӓj���~��m��D�7貹���$r���B��I��'���ق(��,�	�5T���X��{PA�,-&
�P��6�V�)��ꏟ�r�C	ŀ��Y�}�-
��A��?��R�.�ޓ`�~h� e���f-|AU*\7���F35���Et����`�0KfW���NT��4���	��Eg���S�q3�2���HOS�Wm����̛�ۊC��D��LGX�rg�y14!�v�Ƭ權 ƒ��:ͫd��5�%�$��_��z���M�\~#��+1=��P$K@��Tu��z�N/MO'<���T
�G���tC�i�wY*~�f�4��%���?�ϣ/�����?;J���E�����X0���=�a��<��C�g�.�|��n'5!����x£��.��V�~��*��O�X#����,t��]!�����sϝ��Qf�M.�a����.����@���$M=�Հ��-k:+���4)=��t����ޮ���򴘵��G/�+�\�����0���>�HR@ҿ���X �o�a�������	#��t���L�Q�O��~�(ѻo�vۮnYҳ
�m�4��t1��������@�^��yJE� TΜJ�q؍��,J��'��&��~� W�6z)��B�c���1���u�n���S 6��z�q��k�%���oP�8��'廒 ���U���S=�!�c��6�:`	�BƁ�So[�H:�+9V ��,>Hv�܉�F9܁�P��Aƚ ۪&}����zS���t�
��ܮ�ۘo}9��\C��r�+vէ��3�{��-�W��w�J���$T>y�|�Pj���8]O�典(�1����q�&�&�e6	M6��e�jT��R�6Ѹd�������Ï@pkٓ����]��lMx�X�3�����Hԃ�ɍN�Å3S���H�2�żI�fq]S�{|��K�����x ��#���o$N��-^��Tm�߉.�2p9,-����kx����Ss���.� ;����6'շ�*G�����RG��t(�i[$"e�_%=r C18�M/�Vr�>��}��]�u�gV�W�(����W�AW��b�#�*J=��N<�_���H�����Y83�:7� �jZ0#��5��O��ɬ�zp80x]Տ�zE]�ޣn+l��-}�7�1�1W���υ�u�ȥ��-O!̸ n�4�*o.��6�Ƃ�[��r$�� $A��5- 1@����K�h�*�<pf<���#7#�Z\\�*�:���w �j�w��:�H��XP���9��!�D�"&9\�xMU�nǳV�F�P}��8�U�w����Kqk��w:�`Q3d˶4���#��"?�~C�DN��0@O�)@t��MRj~@�a�Ҭ]���+���l���>?[�2�Ƚ�>��-hi�u�b�C��+��Wcez�@`����^M^,�7��*֑��]��͝Yn��z�RGAA��J��G�"5��m�V���^G�b.y�g������'w���殦B�����<� *vY�����5�����+�R��~/�f�u�3�W�d��<���R��'���A�G���^�g�7�?�t�Eu����~h���q"`c�n�q��lN#<����O�_��@u���rY~�
HQ.�Z�ƒ=��g���;���w���͔ՑB������H��H�`=	p�=�{վ����Y�:��v0�f�0У �6����ö�pc5��T����y�.ޯt�D��ܙ�L�'֔0 i䄗���<�&��)t�f���DC���>VmMȍ�p�#Z��v۸QI�6�I�����$������H���R���ʌ�`len���lw;2;�{?���R$�A���t���d=_؊7\�Ț4����7��]���]�&U0��"�CV�4?'gc���J���Ǡu(����aE���gw`(�����|�97l�-�Xx�G�7)9~h������.4�o���ȃ����т]��mjS~r*+��y@�R���N:�S������Ʀ�>q!R�]`��X!����o���D@ex��D�;��C��(����L�.�wۮ�a��!�l.mЋ"�7���]�hP@�Y���?F
�Ѧʧ�b��N�͈2�G�Ou���N�hP��Y�~�rl#��F�����j]�DffA���(���{����m�tS�P$e}ʼ�w&�^
�C��)|���R勿�D�p8g�1k�Dq�Pc���زA�TD��Z`�w�(�;�|�I�UoR�ҭwL�P�n�J�N�C���/pavPh���R�k{���>e���ҙ����c��8��)�ƟH�;ީ��h�����1�����SOE!��_N��^��q��ol�m߭��!��K/�o�R?�� g�>���V�M�G�.I�-"0���v%�rP���.����˕���Z��o��_�#��$!U<�KY��Jp q��cQY��wn�PAo�J�����C�w&�b�gt���ȥ��Ozx�Ʊ��I/8�Ԡ�Jx�b1U��:{*AvL����&l(�nK�B=�w��P�r<&�D|C�Ŋ�;��kv́���O^�ؾ��� ��tS�"�Qv�?>�Kan;�`���@�a�f��Q(6|U�N`�%�;����B߻&��<��>\f&>��P>�|�V(t���b�ŋE�U�P˪ż�oxv#zd4[Bڌ�H�@��>��N��K!#k��    �g�Co�4��z[M�v��
q�]��x�(�Z�Fxf��C�eV��&����x�K
�EuB�>��!H�e*0��<å��灥���[��_�ʁ ��j�K�	�M�����]����xr��d�j�4�f�.��wMSŉ�L��p�d�^ې�ty������*����wVF��� g�<Ш�K?5f4kd���wI�;3�v/�i�s�.ׂ�mKr�D�dc�j�c� JS'�*����I�R���A�b�t�y`a����$�Jrw��-P���2���G�Frv�U]��6(z���8l�$��_����w+��Ԕ,�t���p X�7}�z�V�֩��U"C�E¯�U�*]oG�.�)��u&�)��+��W��8���5��r�ؼ�:RV����h7��~w�B�<k�x�?��ň��;oo�J�]�?D��3�����id���wa��>֔���|��%x�6E�������&t[M_I��z}��#���dQ��nJmPRuy{{�M���i�jX��,
���Q2H���r�2*�]�̏��P��/������Y-�?:<�t�S��8t��b���T�,�b6\�䴐8.��D}qMS���tSY���x�v=]�����c45��6��9x6P���:P�})	�.��	��F����zz�
7s�;�E��"c߉�U-��Q�w(���δ<���x�t�z�Q,>KCY���]��?{�9M�x ��4a�]u	dɪ,/!�7���8F���$%KTV��!�.ݶ[J ��UW�;4��K_����Ad�2x�̯ڻ��CF�q-<�8��9����`���%�O] ��LU���Ð[�ee׮ۇ��V	F��7�0��	�K�������S|�
E1�_|�jYI�-1��ܟ��l7���Y\��N�F��,�,��9�d~Ӓ�Q6[��+l���G� ,I�n�����:=�1��Sz��>�����g=�CC2�q�����K]�o��Ф����o�0�k��b1o6e_�O��3D�ԉ#^Ia<��1��O�2����RA��<Ю?����|2��"�Y��:;Mc��� ��W�aD�Ԯ������i��T�f�uRf��B;<'ER�8�,)��1�k\ZMQ����P%	��相�%��p�W�9�ö\���V'��e/��i٤�#���tg#݆�m*�*rWp>�@���C��#}�b/a?���y|f�
p�?��T'��qP�,��/��I�?��F����W걪;R�n���uwd���ch+~c�Ք�G��/�˫�P}-H��j ;"s�E޳/�	h�+7y��.g�k��:6��>A%��Fh�����C����`�!A,X��K �JGӺ�Hy�O=�p�{� �����z�e���2V�T
ۂu-~�E#����0�y�J�Yy;�HGl�ͽ��音?*[�s��na�O�q�9��1�*��38Q��&-7M.��:�$=��L�J�at�����c���z��;�x�_wl˪��b�G�O?OQ���Z���A�1<�4�'��?�����.�/<g���n�-$�,�P�%���M#�9/��p��5�W�I�v�����_;TR�0c�f�@T%;`F��q��cQ�� M��#@ʥ�)G[�/q�Tn����$t��FX��O���&�}�O<�+d]�=�p����<�;�<4x�X�$sq���7�9LV�O&���[��f��v��
i��SԤC���jz�x���i��R�u{�"RؤԜ<	�G��X��O��-�� zpO�xp9�����ێ��n�64r�TA�{c˽�/�.{�*�leR����`a$�t��N�b+�0�V5Y<e��B8؆��ZW��������H�u�*��	j�X s�\��>n	0��
�d��Z����@4��RwD�V�o���o<� ���2�Lcax���d��b�3�<�\A�5]�e�������G>K����WNt��W�8�����Q�L��7\��os٨��%�W��豠<�05=�?�m��-4�l�dV6�2]�Ĉ⊮3Z�kL�!���Ȓ�Dȕ�b�6c���z��Q��KxF�7�{H�K��Vl�e�Tލg�<</���[̙-3�Xw���'�CS��%f^��̧�)�Xj���+��F�Ar�f�Oi��Ƣ:�Y<a��5I�Y�H��&��	#�_���4�77P���KZ�.�n6�@������nf��>[�,l�Q�%�
E A�JI��r�/XE@[��S�fR �އ�����մ�ĭ���c-��횎 #�aurH�(�Q������]�b��B�8<��bj�;�<��][Q��1�QHE��	�;lVe��	r�N�z/	:E���r�2��}����'N)�M�,�Ƞ�MC��<Ц�,V�IoHpp��gя{�a����7��>VcC�`M�z{��Mf��XY����t���R��e$k����e�'[�3 ��U��fyւ~�1�:H����̻W$�q���(+$������1{�~���e�rFR�|u��v)���V�Y�t����*�H�s��0������f�����8@!����=(��ݫ�}d��)�Y��{1����r��$����jν�)�0}C�X���2�]b*xĲ�p:�2�����Krae���H��\����&�(�E���}#���+��$���Lpr���Lv��nSۡ!mEK��EO�3�	�d������»�E�!c��h.���=��Mx��E��"r��
�U����H�NV�,����-�����l���>��B��Q��L@���l]Z{�����G}S���C����_³�5l�e��ɇ�n.���ew
�����M4&�4]��5����R�c��^CD4E�H�����l{j��cOL�n��Յ.�߰=X�X~z@�6�(�3`Q�J��M�ȵc����r���g��p���Uڝ�і�צ]+O�@y�^�-9a��q���^o���j 2y<��2�B������;��8�.�b8[E�?��ق_7}
3g�慻$��n	���~����}�zZ-Q(���2�׶��)��������p0ޮle�'��N�T*�Y!jMHA��&'�����=�<���S����U����tYjE�aN��6�g�ų����rTT��+��+h��N�B���gŒW<H�����h��˼v�q~�O9ǅ�Ս��F���ٮ�����bt�פU��g1yEs��qV"�T����}f��d���\�i�)���c��{����� c^�jm�^8,�1����A4�����G�ݴcjh�u�G�s������A"�s5P�
F��Z�Q.�e�A�W���~�﬏c��z�>�����H��38�B�"H��)�3��,�Ԩ6��RQ1ӝ�2�=�&�𞕟xS�s�Ee���?�5�A�w�T Z��?�b�}���������Y}3�.��޻kޛqE��D�]���t����G,�'x�Co���TMӸ
�C����Z���#JQgq=���k�J�wz����so���|Kî7�`X��lB��m��9�42����
#I(�3u�V���Ť�ݎ�����@�z��{F�z����3��&��s��h>T��匀�F@���g���f^k�~ק�E��c��-D@vz=�,4�@�yk84؏K��z�ه֠�̎4J��͛a~��z�֖��]^+05��2�f��x��z[���@��=��.6��Q����M��s�]�+i�:�ػ�aܬ��Pw����. )�;�L��ͱ%yl��?��Z�y&ėk&+���j)�����flZ�	��#*x��(���MVV��b��G��tU��t�()� ]@�iI��q:V�p��5V���H�[�C���b���D�M���,��Z/M�����w�Z�XH�hz�r��O��0�G����*_ђ�|���楤�L���A����9�T�m�z�h����4���r��;k�!�8    -��;��:	<��Gt�3��az�����/�n�rk�#מ�F�����B����˖È@�2$�j�Ӡ�+�Z�(b��Φm׶w��!�ECS�\W��(Pܽ?����Y��2�r�9�f��c(Di�����':�O�^����R�n� ����8MΛ&�j�G/=��� �~��y�ȗ���?Vc�8��
��okw�گt��T���
�W9�/!(Ѻţmt�$�J��f(@�Fo�y<�~�w� F��G~��DE�zTV��@J3����̟'��365��L�:i<;u�)�3
ve��V�|D�H@�X.D�v5/�2�`�ՉU/�y�>�1c�O�W�����$�Od'+t�RQ�9	�3	ʱ������#IC�㦯����:�t���޴��r�� ��������Ȱ��q�O�'���ؗ������A�N�*����⭎��F�v�!��%Ri*Ɔ�i`}��W�3�Jp��k��$+W��)��J�Zu��VE�V�L��5���1r����8U!/��Y�;�� ���*�:�h$�W��X ӻC�t$�4�1����ʰlZ'I��͗��Ѕ�9�g�z����g�P�͆�e<A�>4�_�, @��s�lz]Swzd䣢���P��4�9��� ce�Q����(��)�i~��ȉĺ��%{�<Zp��CH�M2tF�*N��mh�>vw��Ch���"��j�"�l�U���W�_���|"�r��0���ag3a���%W��$8w���
5E����ç���|�'~O4?$�t���S�U���%!xm�j��AA���n6��!����u�jxj�|��L�&$�	"���xGXÎˎ�� R�@�k�5�� �X��r��M&����n��%��DƐ�
t�[�&�LT���Z�th���tѸ/��p+�^�Zg�r4�y���Iܦz�/���>���Y&�>���]�_0(J03�|�ZA�8F8ߎ5<��Qw�Z[��"��[9��G��k<�I�	z��a�+TH�h�o���/���+�R���B4��>]���K�4�J�d���im��(�OzZOb4�ʕ�h�P�vu�Q��4��G����8?9�L1X׏@'�ނn;�̗Iq3�}t�|�qP��o<����ri����S	��n�
�m\�?����۹����E��IP�b*9Y�M�G�7��S_��Y���t��
MW>�(�mgXk+�Ф�~�0S�D
w֐��0ƒ�'jI���"M A�� �3� '"cwt�����(Ո����M�>]C!?~OV�Ҳb���?��%������d�Q>�*e3��B�Zn8�CU��@�[:f!����*a�Rӥ{Tˎ@�ߴR���G�S�҇��w,4c_A�j�*�Gzu;����)�����ZV��r��/;d����E�'EX��8|A^|���%�'|��tY�!u2m�Pv���%U1�\H{*���['���a��Īz|�HzG&�;A2ch"R���)�%�Q�3埲�&�3��Qq���#�t�ݜ�A2f
u�u�Vb��{�f���!����Iˤt�����o�L�9���Xx�_o)'����(t-�H;&3%�^"���΃k�s��lb�y7�p9^�O@�����I�����ifG������Y����2~$���?uP�K�D�EV\8>���+C�n�<��B0W
U�"���$�^}+C#�b=qȥG�#��N�ʛ<��Y@x��5�����c���?�
�WO������Ԟ([�TH��AK�y�M�!P�%1F9�Ic`��'2m�g7�Ý�iS	�@O��Cqn�>\@���#�����rs��D�C@�bJNH4������^��X��呬�E�^�7R���4}9@�wQݲ�9o`�bV{c���$�_���?P�����ӑv&�vX�?M�+�jDY_N�o�3�,$6��8= X�㼳ϞE<P�pH$��{A>N6�ۘP�H��r�Sz�֙7S�Q�^3�@مD�b��)�L�)>3�p���~�M�~��B�ۇg������F��6�2ލZ�01M�1�5�?��@�r��Z��ˉ��0���v}w6�6ej+�Fiټ��>��q�|J=R�J_L�(��dL�^RUr��EvZ�\��i6QY3$
�D�=����M�Ͱ�zh֓4����f�}�^>�'F������z��W�0���S����]ف�����#�s
z3���r����ږ!��y��3�=��(C>�]ԇ�3�G߂���'�:_����(���ј�e���iI�ݶw��Pz�v�*3�]�����/���kB��T+�~���\�bJ��A�hx�E��"�d��#��R?G���+ݿ���f|�6�T|,Od&�Re�͠�zK%5t^M�>יBI=���7aW�[:dkӝ�"Χ�%,�_,�t���*�8�}���qe������������o�\T�G`(��'F�=Lw���$&7�N��(%���a�s�E[�Y�#x�v�֫�)T���K?�Yh�k7WS�/��sM�ʉ��`����<����$�#f��g�b[�BPQ7u� �Ĵ��/X�}02�^u�5w��AE��t�>H�,RR)�jN�ƖD��xG�;��}���g":�+�]��RkU:��D�gP�?J�[^�������z���%�*�sqU���&&���<��_�s��2�X��4X��m�@��w��ɫ�~��ܾ�*>8����fR��3�#sN&y�b�#�k�|)���z}y~D�����g��T���a�B����Dw�5SveB#�v����v��-�\��0OB�ے���o�O�=�u&��A�w���f%]ֱ.�)��D��7�\g�f� �DɌ��5�v������I+�u��L�ܱ<&���p���Ӥο�-�$:��{���c��yλ+cz��y�6�y>�Tt7����+�4�g�V�K`R�>�V�4'/���1�'J�zB*O��s	e���S��sˆ�
�����+v&�@���a4����b!�b�r����Z����{��"���f\=�ӣ
���p/#RSfL����yco'w�j��	ie��[��#�l��s�$�ѪmSc|�`
����6m1*�by_��1��g��9�)������3L17�����h��!|:�;z������H�f���zLEz��y��N�0�w@�AI�rp6V\�r�2�ʊ&'����"-��b>篎�A����d����l,��C�|���瞈XРu�t�S�SX���چ�U�\J��ە����������A�A�Q�2B�f�j�{�I�XG)���A���$b�l;I�2���p@�p��Xu�z�s����W������6Z���=���4*�bd��W�;%��|�*�נ�-l��G�|\�e/��B#�����'1�/�=��ӯ7��+�u��\�!ö̘Nāl&-�'�a���~��P{ǡR"����yJ��sk��`�y��Dq�$"�YP�E8F�E1���9��z��V�9��e i��a�~hm�ŝ���V����z��`�C+����X�8�6��#ي�1cZR�;+m�/���Ta�+b�Ʀ"�'��u���;@K��1J>�� y<F��g}~��+�o�v\�4�!�䖸#���s����v��؛��٬���p���xP��L_=�������Ó7Ź���+��TLs"�hz�2|��X�C���$��`�2��{��iXv�G����T���S��鉄*$oG��c�u^>I-��Ec�>���&ӷK\��nA�^��7C��b��ƙ�Slw��R�:I�Я�����������ڈ�u�-�h�f�*�L�7<kJ>�-8x:�������|��5!�^����9m�����p�T�3{���>9�Y��o��y?��DpÉ�bNc6�[��'Y��4�*�]�>��I��e<���Yɔa�g�yn[V��Q��,���'c��5"������N�-�៬&�$5�.�F��`�(�p0M��@��Tȭ�ң
���^�Y康�`�x�%n_�J    �Ƣ��Ŭ���c�B	�٫���Qs�U#�;��2���w��u���bL�0�(�d����>ԙ$w�O��R����ց���H0��ݮwu�>ҵ��fLW��½�	r�f�����B(>�.��a��$7����ͻ��`E=��7w��3 �*�e��5�X�TlIUMH�Ͱ^�ԡI��X}�$튽�u`��QC���z2�2)�$�5�_Y8���ּ�RQi��b��h�N����IŃ�t�u\ʥ�b �����:5!���~��j�Ű�����6�Gg��e��Xs�����$�!�"��fU�~x�ĮW��GNh/��2b�G��g�����X��(�m��]K�1<ҡbђ1v�(�/>�eai��KW@� �+���T��дJ�%=[�Qj(
dJڐ�ō�0���$�Iz��Nv���u�D���s+��p�����+-������82��`�M��]�q-�������d4��*�3�!��^��h��e#}\X�|`E�XN����9�|?���Ǒ�g�JQ҃�v4g�nw�v���Q�\��z2�3:)�.���͖�ʺe�$�� Z;��@Z{��Ὄ8�5,��������x����Ǟ�	��(,{���#�t�A��m���J���G�>��E>�ga�����$��q��=��+�#d9R����*e���#�0j�X�)�r+�nP���c �V�g?�3#5i���fUޒ�Uxnu�>ˬ_�ͷE�/�@�����YK�Ԫ���,O*U���2"���S;:�YO�y!�/Xx��{�����{�f��o��e�+$E�4�F_�mG�����j�k-��u5v���c�����|r>����f7F��/���[lA������������O�W��C���1�_�[M�ϻ�z�V�!�:d�u�����ez-�N���N&�x$�d�%cn��S�nC{�m*ŎDN:Q�2�e������f]
&73�y�E�P���b�q��1��A���7�u��D���\�p��'�87�V�����|³j+*��>�j۷NF���Je9B֘�O&惌)������Q�<�C8#�a:,�
�l�[�@�~s1Uz[�BjiO��������U��_\�|_;�p���gce�D<	>����S�tG�3�6��ؘ�G�|�d�wU���Ll)A�3h��Ou���g8s� NU�N$OO-<��b��TD,zɬ��u-�f��x�PA!�"��;��qkC�ߜ	re<٦P���GW�P��~������Ԙ3\i>��=;w�s��K�;��#a���:Xe���b;T�z`�JV=]��4���QDY7�0�J}E�Oج���
�Q:3]�h�l���G�4Z 	�hI��EH=�.�mz(uU��b�X
��v�l�k�D�e���j�h"���S�ٮ1�%p.��7ut���FT��VS�Vz�vof>�����F���U��D�B�'9�O�`����h��u��?�u�E����ݞ��}eQ4D��{'zk��j�gү~��"���p� ���BK��ŬI��S�ŉ��X3bN�'G"�t�rb��ŋ3!nf�i=!8y�,�_�v�F$��fU���b���d�r�Q9�+����f)�q.A�S`�G`VF��?�f��6V;;�m��[���ߴ�;p(�1A���xSM��_��a�����A��&qCO�o�������OAh�~2��y��z^c�1�w͐П�*Ź�a7=�#�1j�W�cw8��v��U����7E����dH�i������u_����wn�&�"[�aBwi���Gn5	����B�Z:�r����;���|H���yήvr�H�n��G��M?Vj�.�%��N�S8g�}���kj ����<��B(^v{-\d�_�x��z<�?�
�n�CM�.�}��7<�!�
W/��d���RB'H�mz���3];����+���<��$e��#}�|���Ƅ�r$rD��u�w�]��c%��=-(&�ЌC�ު5��h�J��!$�M�H����\k�Jlε֢V��h��lJ��3�7��?%o�R�H��@�te['i���mC��_�]o1��b�n�Nav*�������L��b!9�"×����.e��U���5�l]<>R>�=�z��&�ZX���}��N��E7�; �m�`Y��#���|��*��j����:P"=���)��2����/W������o�ՂS�G �[�f�ʒQ#��몋�{@��%7�<~ʕC�$2��u@�Dob�7:��8P5޷����6�����UZ��>Lsimϲ���"
iާ<�C���!�P�u8BL"�94��Uj6�1�}S>�	��y����l��'}���z��u��iB+�	iEQ����6*M&E���r<�I�&B3b>a=����E�%L�O��i��Dm�jt�I�h~ {��fQD���;���^�E3UL9	���e���4�VKE7��-�x�K��+�g��'90PN�3������=-[%�������Σ��u'�A��f����l��{D�=�����	L������kFM}ti�8KH]¹�?{΅�j>�(f��+_9�1Lc4��FuӦ��9�b�*��OM�9ٻ�= eBr���2�V�dduQ��ʶL��i�v}Zֆ.(�JW�"Џ����������&F��+t��'`��J����?�1�L9�Y8��鮔
�ŀ<�A
�H�EԠ:0�m��O��<����v���UzzL�m+�qC�:��:(뿬����|-Z�e�ܡS��{����������c��wF��֜g6[+�"�Z�٤�CiW��`��B�g��t���]��}2����f`�n*=�ն��ԡ�I-�y��T#�o��������)�]����D+j�8d^f������"VǷQ�5���?��3v&Mn#Y�^�_�/�1-��,{i�]�UR�ޖ���4�FqS/�?�����mz�ʒ@���|���#.C��s��M�>�*�
��n)���?�,R-���fY����6uK"����ߧ��m}�>�0S:s��<����e�	֊w�1�PV�Km*e�h�>���K8"Ym{z�n3�7��`oS�+������Ac��F��i�9��}�;�Kh϶mŋ}>Px�-��,ay&;`�蚘&�g-0>L��]��c�6G�ĐsA�An,ř�*��#v�1O���t�q�LU� V_��>�tE�����jCw^����/?�Ѝ��-��r�Z�,>e��|h�ɥ-�EL�h�7��z%�t�e�~�8Q	;ފ���~HoO��7�g/U��gf?��?H�"#d�Ø[ł`���Z���yڶTuC#�#W:�4d�6ÐL���,�2���^Kc���J��E�E���:�G�vɛ6OϚ9��q|�y8�y�{z=������#\�
)��
�%�v�[Y�5
=����;-�!ڡ^�n�ҿ�tq��R(ǃ�)�:r��'�6���l��a�R"'�I����&���(�_%�^ΏԀ=gS�p�;�Z�C*�Şw��TsZT^
C��mcqh3�l1�Ǥ��Gӗ7�i��#v�;�/Pb��P��Q�nA���z��?m[�"�Q�Aui�ˣ�ls��R�qCî�J��rg���v�?C|�dPeq6�`ܕ�X�����%|����=|��]��<>e��ٽJ��`h���;������0�^=7�N���|�<yن�]WB��_��Q��C�[����o*��q�D�d<�=���%4������c9b/|�¦^U]�f���u�\���uL}��]�}��tf]̭����5����z�'�"���`B�
3��0ϰJ"x��;"����yCB&�`�D,1�B�H�SW5��,��m� ӑd Yk<w�&��L-s���3�M�,
������B�%�Tqmn� ��n���xa&�8@���atkgX�ڗ�IL/�r�5];��Q���]���c�jC��~ ţS��pil�H^���-"f2���ǂ��Gi{w��;��X����4[A�����    dk�8i��a�Gdl�mY���`c"�ᆄ����mh�R�&XR<�
�4Q7�V��&�l^���y)�,��ɿkR�JK9Y��.xd����Hy���l�Lz;E����|���)4B䮂�M��@
٘)ƹ&f�NK
�����n��hC��M����\R0���
�\k['ܾ�E/vAŸ�wڥ��.q�rXD_�WG�D.� �
S��r�l��Q�� @�BMa�8<�=g�&��`�<)�ސѹ^5U��sӶ��k�����W0��K�:����7��B���ɧ�1x��`���&���:�O	�z�HQݞQ�k��rW��D�nWR��	B����	�iѪڴ���i��7�1D顇��P@����S/�{m/�I}��!��º9���?�b҉G��|������B�{��{��$���O�X�Ա���	u�i(����S�5d��B�yR����?u�t�6l�������K�+�>L��K3Y
=UdN��cʁ�-�����������[C5�º�7zcͧiE,�g2��#���Tm�/���^���LǓ��x0��P|�����X�ɷY�9[v&#���Y�
VK���'L(t5�C߃'�Aw�Dl�iH�'���9�±���X�~�候�4��v�JD+���8��ر�=��U�3�OO6(���ea*jLR��_l�K��VD�'iD�u \~ѻ����Iq�W_�j�ʐJ��j�ϻ�uueX#�ft������T5͹q�.��S��Nb�R+�ݠQb9Ѓ��;1���K?p2�j��Ql�bd�c���e�9�)9@B}e�.���#�t���|o;�wƆ]��� �wУ�nϗ0DTߛ�d�~�l�Z�ex^��:�<1a-E �_�!k[�j��,����`��Ɩ7���S�ջZ6/(�����qWu--�"��q�a��*���6x�4��ԕܓ��5׳]Ꜽ�4�IS�'��� 7�.�������s�wZ��&[Ɉ݃�<*��1vIe��1�|1���?J<0��]�����4�a�iǚ�M���k��#*�		��10/��S3^��o�[�H�Ol�W���\=�·(ǡ:�Nަc�u,L
I:U7�����}3.2]腺�z=�
?5Żk!1(00��p���̅��B��J�N��4��?��6[��ȼS���;:�nU���Ng���D/f��(����t�ⱔ�M�!5�Yd�kh{:b��+��jwvN(�܊4�(J3aP�|� �Q	�	�uP��=h��%��z�Oc�l�꺦Y�ݺ�:t�@�h����}�����'h�g�����}���ҰT� �E�8�~��$R%~C�R:��`{��"iC4�^��п�7:=�r�=Ś/�\]�Ri���D_ݤ
��!7mM�Ua�� O��0��]m$����<����≦C�N�tY��U���D�3F��B]BQU/��h���h����ظm��S0aMT�; �.4!eʈ˞Ǭ��׷d5-3>e�"�;I: ƀBg�]�U���:G��	���I�&���l� �⣁~��� �BcЯ+m�w�V�53��ᒽ1�%t�hk��[r�o���!\H k��+Om�G5ۉ7������z���'!Id�����y�Ak;m1rT���� �\f���ܤ��/�ť"�(�n�&��G�x�ܺxϿ�B��ͧn\�e�Kנz�,ْ���>���k|bu����X��v���}@#��Y�ӘEiPT�W�Ql�1ݥ��7����MG�.�CfW!Tc�����hB���Ϸ�O�#��^r�v@XIw��u�0����.��6e�Z�v���F�v�K�e�$DA��UU�����#�e�PZ�����A�;��^O���b負��O���5仹��>�:"��K��ڀ��=힋}��'��Jw=����H[Ug��O���Ö��]���e"G��+2��F� �u���\�os�Ӓ�"�+��g���"ǋt=�hr,I ;�R��Ow9����E�~�to�һpV�	�u�*B�*9���2�P��Ho皂��0T���%݇��o+���Af�3�g�� �*6R�O�m�r|T5M�_6�^As$�^���/��03���	W�0�"��J�)w�6�ʓH��
mP�#���=lz������p�_�gs9�t�+yN�yˌ�(����w�	���� 
�;�4�A�<~���&mA�VbX_p���"	UX*74�ORzz�e-Dz���1Af���9�6Ca��)ˤ"���M�3Z�2��J� �����i(axx,�6���j��r���,���  �_�r"遠���1+_��+ܒ�b�E}OO���*`�M��%�u؊DvYy��_'ܭR�y��vx�[9'�*Af,"No���eE��_�\:�G�j�������Di*�d��Ȯ���I�-<�6͊\��&5����MN?V���X ������.୘0�['nh��3�:0���3Q���\wa���_�(
�J�1ë�)�_�'0˶�ĝ^��kb*wj���,ܢ���Ɍ�v�TU碈��#�}i��t���w�_q�I��ό��Tv������j���M�w�FA���cu5ՂC�m�eb�����D҇0��z�L}R��3D�G�a����ۃ+ �|�m�!�9��ʀ�S�6��QTf��UB��I!"�0>PIڀ�.Z��v�����Lu�І�q���'�:۽q��a��_y\��
�O���YY�﷍��GԷ���4b�~�����7���A�ךX㹶�9�J���m)�d9�-=���
#�w������������WV�kY�'֊yK�L�zv���9(O�6إ2��F�ki��^7cb��z�{�]�&+}8;>I��)h��H�8#������@:-�D������rL��ڸ�m	|4��<�gn�\�Fow��<��]"����\^�QA8�d�,n9��|��s<��y�Z�4ՠ0h;��v~�hc�/eצ���C�܌���3�����HwԎd�Ev5���T���.��]h�6��,�����F�(;�I�`��
�Af�9�R�*n��"�v�?��n��ۤf��w�E:y!o+r֣��^�<�2�.��6��R���OY.(ǿ�l����(U�@V��BbN<�K�^���L��5!�*4Q��t@�A��Mw3�l�!�C_9`Z���~]A�x��+QJ��\J�t������P�:�KM�̬
��v�`��Ι���"%؃&i�z��j.����T�R�F���W+4�Pi�2�C���`���Qz3P����Y�|�F��C��I
���9��"j��n�_d�绅I�}�R_�%BZKy^��$���tڙ�Sz��x�9H�\��X�:����.���ӻ9���^�Z�� Ωav^���5]���%��XӧL�{��E9x�bb�$t��j����ꦬhx� �?7�9+iTZ���b�ņ$�����\a�ȸ�.��g)�N}dyu`Q�̯���'&Ol�;�y�Rˇ�Fm50��=�ZJ��̟��r��=@vD5%jC��ӹ�r68�����CG2֕?�U�w����E3ë�lT��o��I�6���{f��oɷ >>Co�ɄQ�~A$�%#����94�f�5�(��x�j�t�.��chRFf�]R���� ��7���rFP����)�[Θ��X�Og�[����0 xk�\A���k�1�U�!?GP���X	L�p{Dv�WABc�5߲!��Ħ��SV�E�qU�V2!�͸|W��9�>J(�T�oEkܜ�]
�'2O���\�.�5����F/h1h���\��������+��J��J~�Ƙ�@@X�R\"m���re6��f�Vb7�n��,|:�Y�59$�w3��L�QD;�����-�&|�rb�qL��(�����@n��t��9;?@��+���p/F⁮��4��X �RTcM��5%��c��%��KJo��lݑ=���e�^���"_c��/ pUG3�T$_ٿ�c$=|��;��j`�������kv$�.�z1    ��a������{�����f�m{Ϝ?��l$��+�.h�e,| ��{g:���A�����\q`4��rmg�fIw��W�O��0���%Da��Z�ޑMe�G��F�O�4NW6z���͝��1thc_����	a�9�tI�&s4���e�jkEY�����%%�����KX�2 Z�	f��}�D���f�ώB\x�w/q��8T ��$#b;�j�`Ώ]N~�3JZ�j'��|i���K~:&�_��|:	�L4���x�a��L�[�n��D�r
�U��Qm�jh�˳�1�S�X��yf�Q� _{��y���A�'�9>%�6��?m��u�C��oX,*��3���#�hh]Yߙ;��W��u%{Q-Αz�y��lF_���\^I�ix�ls��E��Z`�avO��Cu��/�v?�^L�cl$�J��bɱYOdH�S��d��w�N�)��x;�U#�}5������C��ԃo��1��F?ps��l�ǆ���4H�L�NUn�NLz_/ڙ�ӻjj"j$K���L��w
�M�S2����b�袩�m�JI�ɴߓ\�||!��E��7��	�[O��^$�Q�ޏ<?|䙏���z`XW�K#RT�7)]�v�{�������u$�i;4�� 鑆��D��d�ֹG�#Us�[a+��)bg����?E�E��g"Ѓ`�n*��J��>�� ��r>�ޏ?�6E9��Gk�0#����� �N��j���k���ˬ���³�V�b�b��EiYRW^$Kb��(1��2���Ǭ����BDvH��j�5��ء����Ӌ��|8�}�H�C�}�&��Ԝd/���/��"
��Fȏjly�>d4�{�(����������N�%9�E�XEft��MV��K��8|�Z���3��H�@ ���>S�^�u:�;����v5�Y6�������T2E2����1&S6�������!�#pQ�4O)F�v�f�T��_\��!¾O-�k�������Ĭ]}�
qa<yH9%7��;�@�Z8�� ��k�O�Imo����v��1}�(R�M��A;���4��UMc=,6�}ȷ�ש����F�����&�"�m�̯�\�]py����3C���a�'v
�yp����-ʑ�����J��Y��Y·���唨M���s�s+k���*����S���C��,���p�b����'0���[+IN<<�cט�cMo)+VT�&j��S1��ն�,
��S�'FbZ����Do����[���p$�Me�T��uQ���O�q6�o,+Tv1P{\ԣ}�Qm�����rv�oz�(_x��ȳ�W����^��4$�E<P{�Zt���+;��pC4��_�=CM;�g�n�e����6���Dg_&?��G%������ǆ�VN�_��^�S9
*������M�/��� 6���'a	� �p�8�-���.��e�v���~�v��fx���ĬCޔd��r�^fє�ٜ��w�	!$+�"�D+�WO��E�V��x�@K[y�1{��D��"���N�=O��� ��j{��f�KW/���
ώ$V�NȐ؋t+���9��q�E��FΣ�E �����nu}�Y�>)FG�5�[�'Y�V}�:B�� ?z���x-4Y"e�9��\~�*U�#��㰬�O�4<�m�RE`�m����4|N:�� �	N���=�� Vj�$�3�~�L*}�/�����_��~�F����ДX�i�}ν��u$3�VC7�\���sCZ�a�,f"���l[��dh�K`+Â?-�����B�i&F��s�3(&Y�y���e!A�����{xo��c�/��p�0X���&����)�O<�0s�H\i\�9��ђH���9AB�Tw!XD�%���GS�|�c���ܛW��3~�?e2T�86�b����������͗�V ��5�M�1uHd�S�f،W粁e!�U:�W
s��tp,� �Ьդ7�A?�	��D�FH��2]	YjE���uȊ�
��k�	�	�Z��79��Wa�^D���"1�8\nG�F��<�i}�/��CE��h�?��u��@(+�9w/����<Qg��3o+sE�l�_Y�������ҟ�#^)j�+�Վ�Ca�c�rMtT��,�<��C�U�'�f�X*�z�v�l���s:�G��/4��|�����|2L��o�hK\$��ꎐ�dU���m����w^���W������[�+u:ޘ8?��1�GoR1�+�lĖu�����z��8)�Y0����)����N2�������Q�����O��O������|���^�����k��M*+E%0��R�ޯ�>5����&tE��}��:�љ�h2[ʵ���mU��p){S$�����CȓIS��;.�LcM�h�o䟓��Q�#��f�,@6��Im�����>�q��OPi����F���i�;�D�O/��oT��'^�]�iQS-)&k��G���ن.�ݗ����������9���x،̦>̀�\0�_X�Zw,�O��C�嵸4�������9��@�1щZ���3��O��3(�pd�t]u�2,=���RS���	^2���z`fS<�|�GC�9�z�̃�D��#�ن������Y�h�I���`.y�-Oh���?F��g�u�b!:�������)�J���:���M�|UnB�!60i���r��e�4�OI�U��.R.u�՟�K�`\Hhq��e�."9I��8��!H������pk�4!j�wV��l@�UV͍����[�-�4��9��m�3.�.���ږ���z���t4���M	�l�4��F%D8��$̽8����y|���q�JHn��Ѧ���Q�&T���O}�������� ��=N����8��,٘�)�y�*�T�2X�_��bj����qU��N��<�������14n�;�Q�96Cr*y�!H��zfʜuqΜť�t�,�ɰ��b���\�`I=����EōpBI�K0{�:h��x)�ϝ�(��1����xT��ImL���DH5O�$M�f�bݒ��G�R5Y�nYX瞉�&�e'd��7�����74+�^R�B��idAt�������{l�꜒ڀ��4d���X��>.RR�����ê�m���ަY�OY�����`�o����I噱�+v����u�idf���U��^x��g���bC�eM�,tv/�J�n)�/o|d��΁�V�R���I6�
-�~��i|�4oi���L�q}�|iB����B-�c�����w�Pf!�ũ_��s�&�u�9GQ�M�\�q8)�K���ӏ¢4�JD�.a�NpqP��Ah�t]���a�F����[n���H5����_o�;Pn_B���s�s�KVrdv�R��꟡�U��.�U�ebR�'�a��P&����Xu�VS��z�U3��n4B0:��Q���m�;�&�jMS���?���MH��'Z܅���lΒ5��2���tƯ�3u�wOEހ��Z7�O�#i�K��?�w>��u������>�o���+< ��)*�ҕ3I��'k!�Ƞ�E��<���z\�ILJ���%����w,��hY�R�s��6b�f��e�ozt�1����5����|�aO��5Xn7ׇ�X 2.�M�|<dKbH�Ȱ��u�U�?��+QN-N��%AKy��� X�^�IMc*	��tj�z�m��qyB����nWx'P���hm��%�q(Z ������]�&�Xm�Ps��V>d�L]y�g�S��`�*� �ZKS�s���?��`��&�r�ۺG���.�#��O�'��3�85�,�i���}�]:Ћ�8��E�bcgus��bA��d)��w7o���ȩ_j`'�:����t:	�X�k`ۘ8��N| ����S��c
�l�pa�E��dGߖ'�4Vyj֝Lo�۝r�`������C�y2��(K�7Td�"�~�^qGb��W�f�J�	K����i�z~;^D"Me��R�Zz���_�-M�    �����Ï�-΢n�S����j,�v�3ϲ���ȸf䊿 ����f!K��Ų
XN����>��GQ[rZ�Ux�u }��3Q��tN�o������'7��&�O��]��F	T���i�ѫ�uޓ�N�6(@$�=-����{6�vA,��;�W��-!O�}�@kG��.S�����Rl�erALe�v]a�Ė�Н4@-7��i��i�x�>`?���aխ�Cm����� �ɇ��uZ�j�)qv�ba�,�Jh\t*��̠�����~�e�[x�u���n������[�X���m*�(�#�W(S�fby��324gI/}CwRCS�-	��r"���L#���\ ^i5t�/}z�Є����t�����������3Z��GYG�
Z�1�����&0�y�u���O*y�+β�>[~��%�����0{�a�i�+��pl�[�����p�q��k�T�*2���.�=/�V�i�,|'(\q#�_?�Zp* j��4l���$W���햧}��Lm�ջq��Jv���h��t[�/�5U��/����%�����)�@>�oa�Y+�8�lM�(�M�m��f:�m[�7�������y��
��Qԇ�G����~M��!�BЏa�0���\=|a�T<\�������Ϸ�-zz�B�Vty�]ƶ�<��c�|�p��}�(T��I˓�D%ÚJaz�B)x	kY*�^��N!ʥ���^�u����_7�j���4�N��6!d����Љ��~��-T���+�T`aD(��r�����W;"36��ϼڥח&Z:�	4s,X��M5�Ts����I�fҐ�+QF�."0��E�a&�*���qC�RKT6����rY��5�P�p<���5����+�q�_����! RN;�+ δ9kI5������N�f���J�
���i��d� l��x�(�>�ccք}H�@?.����o�
l6=6e�լ�L�5�6�Y3Qv�ff�GvS�]>����뼯4���fi#X:%dX52��Ա�{iv�l�S�qE=���� ��w?�'V����K\"��+i���������]W6��	�=�̫���0i����ts��t}�	dE>�a�QQp���g�؅�{�Ɏ�p��2̙wd��.d2�Jv��BN1'�<�x�yƘL>l�>A0�f�.f��~\�XB�}O����5����%;���LU�ō�5����b�Rḥ�����#�?"�0��C�D+1�m��M}���,S�DP�--�pޓ�DU��AC�ώ�5��n#����n��� b�"�+/A��	���5���2=ݳ�z� ����Ϟ|m��Y��0�$P�����鱽�����<�a�!`�|j@%��^��v�Oo�(�˻�6�Dy�AZ[��xO�L�|��D��W�ܵ�C@�ťD*@�K߰�~���e�����X�Ն�[=�<��-b��CH@,�-/�<�tɗ7�]�w��mhG�m%Ԛ /a�NF
�Do3��B#���/_.�#	�mL�P5a�XHdԶ�E2{�q�vX��ƺ�O,�7s���.;3b锄����h�t��۳64G-�}~�P0&|r���z�T,!�ܣܵZ�f~��EUY!\p�5�Lu���S��O���/���Ԕ(�L�!�+�r�>]���$���|mO�����uQ�� �x��O��.��*a��S��`D]Z1�����Wh7�#�KK;͓���<@$�êڮ	˰!�U��QI�T�>�saiam��".��w���
�QX�
ڌ'�2Nd�4(v�z j���8,
i�B�t�rH���<p�y�!��@���/�yT��[M�C�|�Rh��yYi)�k�UX����X���Jo��_3,���v���&�8�G)��r�,�/�w�4�0L�)��LJ	�s��M�A_X��C�|Ꝫ}�.#t�=��T�_����NHn����`!B+@r1�È���&О����U��h4+��X�\TFf�U���#�C��i
4���?s�q�W����r��.�fN��L�,�xa(Fܤ�܌J5[�y�Fӟ/,rU���>l�j���|\=�aq���媬a�_�mg%t"�M����hCG׭+DQ��V��S��g��R��	o���~5n5��&�ݰ.�1D�1B�8���'���d���y���}pXA����^<b�ԩ�� ���8L� ���4,J��p���B'�M�xEgnG��
�e�ϵ"�湠ʄBH�vq��Vo��6%#�z	 ,,�Y��sw�e\nG��ԂVNy%�Ԙ�2�MY�R�>3S��d�L��KB3�Di�I�U���"���ǋž�s}������qB��_���,Z��Q���(�w�h����E�\L�8��
�����ˠa�pk2;���5hڭt,K��h)�R͍O�l,<�e�Q<�IS�G�f?+��>�ة{����l�EQ]�P�5�RR b����;���_UC����M���G]����H>вhl6w>�Иuۊ���^�PƵ)�%�*�o{j�,� �؄#[��f������ע+��n�/�e|��Slw6��盘�Nz���'��WY�#2��&0� U�J�-��4�p���UN�1���4���Mx�.0�~�b�@�����w��`:���ms}��p����o��0T��eeo	��V��P�0`d)9a��p����R�.V<ABlc�8�\���Áia��-(���:q��%�b�e��*�硘�W�us�Y�p@�IP�@�)j��8��Jj��7��'�&�`�tE/Rv�_'��R���1�)=�db�,�A �L&�W�u8�^5b�{{��+,Uh+��u'�vl1��J�,dJ���IްI��p�c
Y7T�A�0����9��c�xޥQ�,7�����דe|zL�P�*Vn�^�w3&�5� ˧<7	IF7+ē��	l&g�i��$Y��fHߐ���XC�\Fw�����r�c߾�@��?�m|0�̝V�5������~ք����I��܉��^����ԓh])��?fQ&�͔كB[U$��k ��2C��~]=��1AM��P⊬���6��|�8GcءFs�;aUŤG*aCo் ���Nsb��[�xq�LPu&�+��i��Fhm;.o����L�wؤה���C<�����x~��#+xKM霐2�a��8E�K�'YIb5�B�3B�º+fV�xDx�9t�
+2g�KC��@����f��'������a��Ž��NY΢0|.Pj>�BN��㝤n����>��H7���g���EMn�\ކ�t�/�&�lH����~�o�\җ[���b�̂Ԣ��&��Xm�fy�ه��o*�٥'�̼[�@�Mo�d��0ь�yZ���1S^��v>�kw�B��LaR�&�Q�Ԧ�*+�����%�lWXK8���m������CC@lUGBF��'���Gj��"{S���!��9��-�Ei�A_|+���(��k����y�
���:8��0%B�q{Ac�4���n�0��P��m���Nn�r�2�����̖JOfy��4߻�*B��*X~Q���	��n�?_y�|���=I��:��HW����#�R�B2�+@�Z7�?���p��ٙ����l���*ֱ�+�>�}G�ɝ�(*��eaz��C͆,�v0#iuWN6��Y�H�S3��:���y�Q���`���3 B�{����i>�7 *��	���Y�{�Cы�N����<�ev��՟侠cN��A�%�� ۳�f��6K���nh:<�r&+O]Y:f�-O)<Q�d�&(ƅ���`:�~�\�*������.O�-��ѥ{㩼�f�0�2C8�8B�46��oGxn/�'	��=aP�y
B*Է�B��'"]-��H-�t�{�����i"�|�IH?����k�|¡�H�7 攒���o��sx�z���T���K�n�Z�\b����Y�;�ĀÛ|�}p�Z�J���L�:��H/�o���J�M3,/���Q�ʖ�<:e��5`u��Θ�,�EY]�沪%�M�Q�    y�ȥd�$o٨��,��{��
 ��D�}/ff�1&�,��4������U>:�]�a[��vC`�;8�!�"C]IV���y�3�@K�]��)�l�Y��G��%G8(���R��֞i}����Ea��
Pͷ�$�}��wi�5FX�b47�`4z��� ���!<%:"����ږ����|W^NG�����\��I%�Z��-��2Y�AYcY/��&�O����8�>!�v�����M� Keԟ¼ �pb÷���G�U����y�V؝[vCF�:W�X�,��~�n�]���Q��D���b�P2��ʉrv�d���q�/�>(��e��w�� ���Aݩ�Jr��*�SZe��@۹5�z�<B/3l� !����y&R'A�~R��I�o�[^�C�%����*k|��^��B��=u�J�w�����j��OZbuO�6�j�����(BGC�g��w;Vx}���r����}���2�&׻���?3\���.g���I�X�PY4�#"_��� uو��KLŻ(b6�r��on�M��o���л�256u���B�2t:5<�.W7�@�b�B4�@��	��g�&�Z��`�l�
�t��?��q�[���B���1��̘����a��B+1���$l���ߨ�D0��"p�������������1�^2E�wS���S���kfSy��~�'^1^ư:��>�A��nS�	��1c�9Lw�7���v=�x�O���Y'I��\�F ��a}��Nj
Ű���ؾ���N+�+��nI\�y�-Z��3�_U߱x��S�,�[z���އZ�a��k�-��~~���b�2(��^�"�ࡨ���8�.�N� �4�k���� �x$�D�q�~��0��U�{�G�s�-b����rPkz�AǷ���#~��s����y����>�CK��4_�crF3���ݏ%�g`���=y�����?c�j�]ؑ���+7(���g�s��,���Љ�u�ni:c;���v�,v.|1�x/�2W_�Pb��{�X�_M�t�䙒�'�G������>�xK�\l����z\v_���~�05�ԡy��4۰m��Sz��!*��Đ��9@��|x��B��B�ț;�n]$U���A �[XЈ=�çe;��ώ�����;���ߏB���Ru�������/*W4j��/h����_�m�t��Q��m���bAr�8&`X����vY2���v=����3B�M�Ē0z�����Q�����M��5��X�~R�K�r��cO�.,p���"�	?K�$._���9U��p���6ÝAY�r�Ƕ�O8�Qt��<D���<_e�Ƒ���A$��DU6u�w�<)hET�"Ձ�ǰ�h����ȴ�`]��j�u�Å�o@c�NKd��tS��qO��T�l7wB�BJ{?
#�*|�����p)��J�b�33���J��7�լ������Z���A#ª���ٴ�fz��n#M�'��xU9�*v6����{��v/Pd��_h�j�ǔ����1�����i�h����0Z�����R���g�U��݅;MM��׋��!���s���6J���I���|����EpZ}/B)d��ueR"��de���MX�N*I�r�E���\I�֠2��OV�z�'/��bj;�Gc�7������s,G䫠�kʦ���k�Ň4���a��([�`0�cO����f�3��4�K�e��A@*QL���춵�Y';�@����)�|�4��K���5B������οQ��؟�?0R�=:� �xC���䂋Z�!��7�^䣿.y�8נ)��tN���w���)�q��>�W�ݳ� lRhz����gM��h�jX+jZy9�oK۩.�g㸨�BF�@i�½��m��Y&o�9�(m7Z���77W�,�C��al�n,��2 ����"�͆+a�6�f(��D�8#��<�5	���h�"��^2��#XF�!;|HLz.��Fӣ����������w2����T���w(<���ݢ�aySðj�!	��Ź��8d֧sS��G�`.	fJUw[ΰM/�fq�8���!�B���PQcc�+;��2���P�m�-�E ~������O#s�����4+H���Vi���a}۱��*�7FWP��kL��2n��E��b�SD�������+P�#���������;����4􅲶�v�*��	,�Hy&�rJ�PWC;ܹ=��w�Ʌt��b��H��.Z-hI��pJ�Ș�4W%����2�g Y��(�	�rk�a�.��D$��x�W��8<��1a1I�g�,�A>E�J��Jo�A�l�B���*����z�G_^Y�p:�K�Ⱦ�9�J�Ъ?��c��=�pM>2���{�9�Ag�&�5��!vF����������Pl��!��3�V���KM�$���q�x�S
x���^^ۿ�h��d d>�uܓ�E@ŏ��DU^0��Z޺�O�i�W�m�>Aj9zQM'�"��1�"�_Gg_*�So���N�^W�A�1�k��h��2�N19���/�i�A�>�H�sH"�)��"�3��h�7Z:��l�R>G��xL��6���Y��._!��5 �Q��po|;Ń�*�,E����T1m�{��,�Mj��1_ �'�<Q�|�[��D�A��`�o(αY��s_!�{H'�η$A�ɴ�qgl�e�6����]<��q!�`���؟W�nc�&���=�KZG&�5�O��;b��ٸ��+������Kxl��j��,,��>�W���6`����də/O��S���W.>}�Q�`���[�Q�/kB;��j]� ��$����`O�E�oo[:j_k
N�e����N�N������6�����uvQ�3�\M���:�f���b���z�Ү�H6��	�.YPp��c�8;Ľ+���O?Z��W����Ž��+`�d��%M��8�o�D���CH'ր���-���5��(V��Z$A���ڗ* d�J�����<=��>�;���#&aX�%�9+�8V��U4�x��@L�||�����O���}j�S/ӱ�x�A��&��b�����Vg`t�]�[�$�"4%7g�@Q7������E9ydGeJ3.#��g�R6��m�����%~+*�� g<�X�ˋ��#P*�L�%5iK)�ˬ�!�|�A\�d��	����<���/�w;*�ߝ��҃��T�,���q^T���y��F�l�9�>�~B4���.�-I^D���:P�y��CFΧ�� =�f��Bd���K�\� 6/�|��r!�N�O3Մ�/>+��3����$2�O�����ѭ__TF�q�>o�4���б6���v9Br�C=V!�z8�$�hM`�M�
SK.�(Y � r�H-IS�t�Š#�!��8(��P�G�h�@�����DKI����ʎs�!�K��f8�,�����Gr�Hp�P7�[(�U�X�9XC����������wA�kP �E��gf(ٟ�JEԉ�J�MM1� �^Gf�����92݃���߳��E�ҿJ�f�Zgg���W���'��K"�Oف�yMפ���C���7
��Fp�����pɁ�fJ�74�vݢ�qY�y���6��� ����e]y9��8(3)��(>��N6�5���p|�A6#�yK�ܳKT��\��GZ�h��++bl��h�!߸'�l����2	��'Ab<g�vz�k.u�|�!�Hns�'v
��/�\-��;�%[��NÀ>��HD����;��` ������,KO�H@��)�UKC���r���f����v{�ae���M5�E�t�r�Rʇ��r��SY1dH���.���4�\t$ш�w*@4X�zk��@`EF�t7��_����1���1�j{���u��D�W��8;"u"-���s��$ݵ� Q�M��09��s1ǗIUL�'��Ȝ^����Ր񟝃�#m,>-�.x:i�t��(�iI�    ��Q�3$���z�^I�æ���� ���ˡ�Ҥ�u˂�����s��2K&�:|��Eג���W��Ӂ�|s���b���^��؝���f�؉�ö2]���eOс�LUP�<��]lH����֨60'`�r����3>Q�ӊ�+��N<�5%<
��![bX�9m����{I�`������}��nk�g2}�m��BCf��*h���a)�p��Ɂ4����[:-g��Ȩ����\V.R�"W������ꗽf-CF�r���f*�����$������7�&���?'�r�g\80�ʹ#��Uլi�12/������Ǒ��P8m����'�Jvd)�9n��%�b�Y�dA6���^��x'�5а�_�����c�����n$�|2��b����؀T^�}}zp�>p��Ѝw\�S��pAJ�Jl(�O�M !v���[���Lt�����&����e��`����$m֘�c[twbߵ�O��h����`�fvJ�p�vˇH'���40������v�����O��9+��bf�޲��N�El�FS���}��U>q�}��NR�1ὢI��&�������̡~;	�\�d��x��W}��k5����T>[F�*$_^��&?�9�s#���S(��m[�g�
�cOo8��\S�'!�@7 �{XdByC�j��qЌ(/�xl	�V͸^�݆��!���G@T��3b�T�T|�3�@�n�N�D`!�?>h���.���doH��[�A�'�Z³)�2?("h�������v(ܮ&�Nw��z�f����ʣA�ԩ����Ee��T"��|K�~s��=uD9�@/�L�s����kd�7���LL�b�k��6A�3ҿX��.å�_]��4ҕL�D����xU|aC_�<ʄ=���{�S��)%�΁z���8�F�On������|�EGQ&M|��t�q�	�]���CL)��|�9�Hlu@=�N/c#�鼔x���'{�UQ3��g��i�ֵU=.S����=4}%ZD�\�eQ��,ɈDq](il*u�_�`�z�%Ph^Z �:+,��Ȗ�0��f0���������U���Ғ�Q��j�6�PU�,j���b�B�	8�GuMRc��Gj�{�k(�t�_$SR2��<��
Z\�B�g>����E0� u��N��9̚N�v΃ �U�$�&�V�C����醹H�P�]�,���C3V���i p��t����b}��sY�F���n�u�m�@Q��`3�ó���/e�:�P�1Ԅ��Ew�������5�3՞��,a?�ؿ4�ih�m{g2����B`c���^���Kʋ22cỶ��%l�Y������"��lm��3,��#K���:<~�y�M'����\lis�����# ��2��O����Pȑ��p�mA��kع��$��'%tY*t�}vW.�U'��v�N�o�� ȼx�����>~�:��Gګd'�];�j���Ѕ��E�r�����M�D�.��I�)ɢ��Ud�<��gPя�[=G���ݏ�`��?u����}�8<��e�V�P�8"�0�(YU������C��	�e2ϝ�=�Gۦ�����ʼK1t�˛�kS��
���o;�<j=M�1ϲ���A�Q����D����/y�%�8ˌ��)��h�m�t7���!$M[TF�����2[��
��`��������<+Oh�C�TXc�����,jx��_��S!?��R�"�Q���wɟ--v��Fd*xF{N�V���X�u��wȌ�v��;���ҮM�����]�ަb�P~��Mz(f�X�H�0����g��(hQTH��o;�0Q�F�	k������Xdr�W����A{��Å���*+���v���G�����ۦ���V$�.�T�&'�i_C�x�|4_�"���,irg)�k��%
S1�Fv��c�_T戕B��<"��r8� ���x>�8�������. �!�ʖU�672���7�}M���}��x-��f�#2��f/p�Z�:��`���I���@��MR(5�HNL�BbAp�� �]V`�'z��T-��6O��������]�K���Z`�Bcb2��'��M�햣����=�ǯ�g�ݱ�#�!M79����DVq ����
�l#�JV ��U9����?a��	Z��G_n�%��-��]�۳U�a�\��Ӂ:.w4!�{؎�������4���/r��O�)W�-�aQv�Q���n���$�;�ܰ���	�3YԐ�L�Y!��X��Z�I��{]A��⇨v�A/&�w# %w�@�m�>�t��b�R�NՖ,��n{Ui:|i��3{��nΨ����z�S��j��g��ۑ?S@�`�x9��NM�T>ISw��MMٶ�f����`�M�tO�ۆ@�us���Cz�\8 ���X�o>���
,o�woG	H����\��%�� �۠� C$d�]8Q�
����1�Ox����m���xS;�A#���_<�Cl��B����$pxH�*��	�v��� ��k�3F@�е��S�8ա�HM�%H14jWp�h*!�Ji�S~���P�#]�|��}���1�C�T���h�nj�n��<^v��=�BD���"On0d�	�-,K�s@��\�a��8R!��CX���5��`I�T)�T���q,;ִg��!���tdmқ�-G�!jzH�Rib� w�o��c����GZ�/������eX�����0�G6�3�J��8��.}r����~,�Me2�*�a�cta�C�V0�ȟ7�XO7�I?���f��,X�f��ӯ8��9����B��\=ψ�`�;e�Xy{NJBs��$9��Hۀ�)��~����<����-��X���t���]�Wt�4�,ꁲ�}�c��Ӹ0b[��D�ߚH]�rD�Lt�9�%y�&�@���~��.I�w�X����	`�Oq��b�^��h;|4�bH��q��Π?dSm��T%�>��E����Y1��O��u7
��HRG*���o�o?�Ԣ�k ��Rr���Άw^k�uǜ��_�ouM�n��!�zh�ʎR�{�)�n�a�t��J2U��LMi�2�d3���M��\����UF���D�t<&;#�#x��3 �E�6_����B���b��Bjִ��l�� ��j=��R`x(�bSz4��P):(��Y�S=v��A��%k��Av�	�\r�a���gmP/�f �P^WA�XVA�R�6�{;w��P�w�W%�L�0�JR=;5��.��:D':���?�Y�������h_�{�����%�/�^�m@:�*ɑ�diIv�~�~��R����vl�u��J4HOzk_X�����\�3�d���D(_Y$�Q	m�RLӧM5��$`㊈�]u7\m���T�ѐ"O6�+5{��Jcq��"�Q�;���@,�������!�#ݦ��[?OC�M.�P�	B#g���!=��(�]�$�BN}��7���/|���=�l�b�Q���_�&7�i��@��/���[ua�H�M3��c(L7,�f!E���Q�(�?�u �9d�G�
�d�+�:�S'q���]1R
����;� ���O@��K�<�bu����I�*��M��z�X��Vz��-KoNW��ׯ�'�s� n�S�8��jHg���Q��;@q�4%c=��O�nFcp0�(�nR��wRGpL��^<�ir����c�Ŕa�T�2*�~%}>���4/�'K����t
l`������r)�RB��a�?�����1ɱ{�`W��75Z[�� ��Ã<�_�T�N@�9�#�!}sw޵P�w]�ʔ~�71q��aA�x_Ejs�_�O�H����N%�a��Sp��t�	�/�dj��tn4�3��;�L�!���*�u�Gd��\�P�KoI<���U����zΗ�$e����T�\����ЃX@w�I��Fx�ɚW
[����˵z�,�;�?������w,���x1:�����z�M�$�:��P0�.���Ӽl�4}=p�&    '��ڢ�������0)M7>Ϩh�V���AUH(i�mu��2�d,TN�!�����43ܗ��X`Lo�G~ۿ�O[ ��
�a��������f5�����^�����!U�F��4�P88�u=��Nf"�(��f�JG�7p��#�DA�n���fVFIetِ�`Fr�Q�)'5�H%�>�c�s��������IH�Z�׈GC��l��d�E��#��e�VM�W��!G|�Q��TI��eȷ�%b��	�4�|E'�
��A|J_��rtb�$US���y�J�@��#��=0����$���
�ߕL�����E�O� 8��*�G�l�z���Iz �X$L�>�C�G���q�GӕC�#Ԍtn�B*S�/!����,(D�}S�t��-�6@֯'��D�Vp��TL�R��]�}�� �0�G�/�Y��.�>gߊ�ZY��41]K'qCы�[�q]/�F!�wH��9��,IOah����n�ĈFHUS���& h��Φɣ��&��>�qԗp	��Ð-�G�+y0�K7�:0��v���f90pa��&�KZP���_RO*h0h�g�m�>�����;w((د#
�y5�]�JX��$�K`���_e'`*k=���F�̫FI�RJ�,�ٰU�����1����r�8�b����޻�Y��'��\KSp�f���D�8��r�`��X�(�;�����ݽS�R�g5izyg�[�m�K��P Z0����ܐ��N���Y.:BH��w��J:
�C�.�a�d��W������4�ܤO�H>��!|��+��`��5�KRlg.��J��k�C�%�r�-ɔ�8�kr����IH.�u!W�@#�L�qM������a�z�}���~V/�)�刞v6%Ǥ��yx�H����"�x�����,�1��#�`?.g}!�x�S�a7�2�v�j9T��2���3�,�K�~qy�NmhbHv K���L��A0��s%dC���nH���2�?�xV��Y_S�x��^Җʷv9K{Q�E���c�]0][����r5_3� :
Zf��-l*�KidT���ל���ѵX1]��:����2=A�R�tڳ�X�Z��,�<�������-�d�;󽐪<�Jc-��ɥ�W8�w��9?��'o�"�g����GYm��/�gL�DG�?c\A�-2f���TF��;P �����4��}QK��e��<��)@��Fb\���d].=�O:��Y�
�m�@�BJ�0ԕ��?��$���O��z�3� ��w��8���k��)�4,��S�tQ#�8�H������HSbhO, ~���E�د����M�d�U�b�����!o�H#��[/2S�_�>��LF�>m�g[�L���)�#�eL�,ȑE��rh�ګP8�8��d�8Lf�z��Q�� Q�i�2�c��C©�W0��CS��s2�e"��^�(D6����1E�����#}m^z��9{0���ۑ#��;aꪘ�X*X�OWg�.��¢Y�P�WE�`x�WՆ��]��;
��Leϻ�]򊳶^j��=}���2���Y�d�b�C58M���s����������:�T���s�D���;�mV����4�7SZ�g������zHg9�Mj����O���t&ȣ��ͦ\���獗5HH���|G��˯��$I�'�#}�;]xB�b��#b�c����W6h�,W�i�|��}��U$]c���,�~R��|����L��4��Չ5��&n��}Ogi6�X�Jc���ʕ-����}��|��w�\��L<v�K�a���a!zy�JD�L�O?A��-߈�! f�:4���|�٧�$~���c�!��k��} ,'���n�%:�q���<-7y��cF�q�Aj>��`�T���)�½�$![y�J�@;<��7C��|�<�rɷ_�;B)�+�?�%��C:����.0պ����B�P0�i�(���?�Ԯ0a1��k�Ъj�Uߒ�P�w�!z��ޖxy2�[��c����9�g��[�A�5r�����C�O�-)5*�8���+�D��=�E�&h�d_�P����)ڡq]ה�9���+�9�8W��p�zHy�]V����?q�������$�q�u�e��o����<{�C�m��ĉr��������w2�t�ҙE�F�EV��̷"F�A��,U�ym���93̉�8=����> [1Y��R��Q�H`��G�o-8��G��뇓��[�i��}&�t���Ֆ6�K�lȄ�M%�R�i.K�˧�3��٬ۉ6?��#W��h\譅�%��f�]yt��7�%;��� ,6�x)�`o1����_<%Y�	^
A$���P��vYg��b����Q�bY�yK2c;͝��W����hJ���!��FRy��S�Ýp��i��Y�mq�C3�Y�8o�������t]AL���V���FG�D��"�;MwȺ�m�����%�uh�����M������2ӕ�J,.u:: �%a����Q�h��zq�������觏��˞j�.b����~B^��
U�@x�NO�O����Ĭ�G"��q�jM����*dv�� 79�ݷ �������F����S�)nZ����B^�V�|�ot��o�J�Զ��w�I�~���E��!����� �-;�6|	o˅%g!c�S=��UCbQ�q�v	ۈ�M�\�2�
�PZ�6Uӧv���H�h��<�a���4S�l�
�E��Β����z�_���$rQ�߄�;��Ps��!L�s� �]��)�GhrE����n�� �1��@����6a�!q��HE�iܹ1�1�(�,���\}P�ǝ'ų�h�| �>)n5ua��^C-O/xZ 4�ݰ+��p����a��u*1UꞁgW��[5Ֆ�H����'�c�����-�x$�1��<�b8�=�8P������Wz=�������O>�/�]�|���Y�?NJ��!�Cu[�.DϬ�e^'��X=�|A��"�S%\S`�8v��Đ]>�ו��a�G��쥜�N�m�X�(8�/�䔄��(��<3���t�$N����U*�4e6��]7�$��y5��$��Pr)/	"BT9)pt���L4uo������lq�� �z>�Px�%�r���Z�5�S��YK /��J��b<>=0��p
$R���4��p���<�1$��k�|_�H�:S��vN�+��W���w��T�����2}��9j���Fߔ�"v�WB�b���AT*���K]���<C���"۰�������SPޓ�)�u����n�?�1����y���ó�p털�s�t�S`�p�M�V���V^Ф��f����O�0�k�
����?���09mF�NS�x��H6Ɋ�v�]j��j�$�~m�6�k>�NU%��Uȿ�1���������/����m�6 G���$(�V�ù)%n�4����b�����h�[N�ݖ�uV}��zqc6���1�7��u��uKl'~v�ӖF�y����sv�x��1��!ޮ���< ��j��5Be4�6��3d��N1vL��8���	L͜�[;�UՌtst�[ڬ�7c�'g-.6r�`v�Q��H�bF�j)m�$b�3�o�k�!���܆�A�� ��I����2��zt��D��1��܋`��ՐQ�j��֜l�����ڷ1����o20 ���PM �n���`����6������9Hu�*b�s�^/�A����q��4��&�Ȏ��^,wǐW>�){O�����l�^Ų5nc-���ˌ�Qp�G�Mm��Lg��6�d� 7�3����-r����"�nM��wgh7EbNNs
�1�>0��Mi�'2_H��BLՆ_}��.C���i�ggwF!(��0�\��p� �s��ݔcZ�5* =A���.�]/@�	�AyP��"M�P��X!齈�Sq��"=�z۪�.ӂ�:>������vr�a�7EnU)*�����3Vx2�̵��K�7�r�n@�04���?����Mr������?ٱkW�Wò[$����_�5    oW�*��a%L'��w�ڃa�;���+�Q۫�Y�R�6,��+����w�X��U�?M�(Ѝ�\��o�"$C���\����Z�h֌�MZ�L���F?�����~�m�!��g�a��)�j�_t'�!}L׼�S�D�z:�/�n�qW�`��s��MU�㋱N1m�g��[���#x��v�O`�,��;����Pg��>�w)+��z����4��1�t����i�N�( ����&ؠw[ݲ������>��R��`ŮO��d#�<#�|�pG�:�N�L��,��_�Tv]���7�;.x"�@�������8$�@@=b�ag�F	,c�|a�����V�ByF��+���Va���t������1���_^�q���)jJ����Tƕ�?��##cA�x��n��v�ƻ���x���Ki�Z���eӪ�UO����e˰�1���WZ�=�g\�0f9�eٯ�9�	
c���/��b%1
�.I���A�vt�b�0-�k��]���
�L8��swF�uΔ� ��-�[�� �1Ĝ���1H�C���:�~���O6�0���(.��>P�O��y�5�e���Wk�x��ᶰ������Z�K?Z$�wHȤ�%y>Fx!��;��"w2k���D�����p���1���u_��c�K�+�:I6�qg:�j�|�Q���,=��HTbl�*>p�.��}��P�L/9�,��E��B�����QT:˳␋Ni�n��Md�^$�x�ic�P��3���%�:{�9EΦ��� M|#߸ q�ѹ���#�y͎(u�BI���_�/N�n��-O�����%j%�5�e�;<�a�!�}L�z�}��{��˃����f�ȱ�mu~�0����-�!� t�%��<�W+���p#oX��\Q���]Q8������B�c�cj���M��7<��u��Z�f�
ןu��W�������(��5��1(��������1�͟� c@\�oe�OzVp�&� �x�h��GYԫz�ʏ�<�}R!�ݴ�y�{ӁR$���6���L{��$���`V��񗓩�d�U���ߡuqV=,Y�����P�4�y�e�2����T�3�F��AN|S�i[S�QK��~X/�{!*~���E����M�D����#wH���F�L|�#��@��"g�I��m���
����uH�J�2m��V4���L�ۆ`�}��ܩ�Bn��!���,6a��t�9ɿ.R��ȘB��U~`<uwqz�n���9dC��p��}����?�H�B�kW������di:���Khl��U�cl����J���k���-  �G�1&��
�Q떪$s����S�3�V�ʉ)�'i�f�ì��r@4+o��ѧDx��wM--1ǮjiM���E6C[I����c�嚢`�,�%�xF������v�U�*�[FpB}吻�fy�E2.@`D�|�/\rB����x�X��<���(ͼ�R��;�T�P��҆�������>nH��*�W|P���,��Q8;�L�.�l����I��S_�"u�B��W���<l�-�NKR)�!�9�E�Z��D�8�"��׼[��!#������n���� ��~e#���}܌w���pm����{HU-��f��@��K����j:�-��Y�^���B��'���xK���B"���O_1�%;�����T"���]Qi���Rt��6�пW��^k3T���a�n��`n=�_�Dk��ʢSX�{��fV �����*�l\�a�I�R� ϟL��%($F��*z��`��sR[ߓ���;Wv胚u�I�OJK�o��9Fg ;�M�x��4�g��"QL�}`����(h�^ĠT�d��T�
ӽ��;`M#e������vy�R�G�5���΄���_w��k��*=��i�yX?܈~���"��!D��1��E(0�Xt�RV�@]�Gh�����F��% 4���o�� n���#����~����c#���VW,C7s�C��5��-kLy����n���%&�b���=4�����˔p2B�]�$���T�5��q�]z�i���,0hmڮe"�Z��r����R�X$����"^Ζ���`��y�f7�F�O6=�[�,��	B*�9��:^�?�6aBr�ov��N6�*shW=�[R�2n�=c���m��P��Z�����7��Lg��
a��#δ�^��2-T���`Q1g�����ZY��M��$?�I�
�� ����0-�:��Llߦ;�[���!r{l���ǧ���!�-X���x1F��	Μn�<=�j���d	���^��;&�j�C������*`P�)3۞e���`k��I��XU�fũ�}5�͢q#=��I���	��o�s��t:;��4���t1φ��~g_��� O���������b�TԜ��^�FW� �w��P|�g�;L�Sҟ/l�[�#�'��5	��נ�EF8��;8��Q)a_�C½��%�D���ۉ������`\�j��5�m�*2[ʮZ|)BI�j*{�1ؠ�ί����� gZ`OM��(d6� ڕWf���7�,���2t�a�y��%�w��I!��t��#%�A�O)�S��g����<��W��b�햷�M�W	�e��Q�-R�$��I��M�y��*�dJW�X&�e���&��j{*m5�'ҳЬ3kB�{�	���k*T �O�`��}�*IF-���n�Ò4ڃ��Hǖ<7���7�r������"hL8��ͺ�,���P~�<��h/\���^��a�DZ�G�F-Y�Q�|̈��	
��%�p�Z����(͈ ���jl�H0B�x*��YBhƨ>0L�:צ���},;�O��R	3����c4�`ҝ��0250p�n�DX �j�T�� ��]�|)���.O;B�8-�b������f�3/+�L�SJOg\��@�λ����?���3�
1�X��U���/;�~Ep���w��ھ7D,ش͢�r���6��\���Q�ȫ��@Z���������M�Rb�Y�+e�@��!�� �!I�NH�p|� ��s!w鵙� �5��A"������ű�mǱ�?A�t�	�\脈�"ʁ�A�ȼ1�����f��x����ٖ~�~c|�BQL}a{*	�~׾qv���!�K�	��X�뒘6ФӒXW��k��Nj��!a���g���'ח��NO~[�w��!�|ܶ��s/=����Z�|�m��գn,�M|G9�P<X<	=�7[�����/�KXt�,�4���G6���ra��H���d~���fҼe�btԳb�`/r�W�o:�7�z�za�#����#�	�\K�^����N�Z�>�Sg.��m��=�!���h<�@<|���P|�>($���(4T��.�tL:��}����MԤӱTY�jz����C|���+�!\Rȸ0I�W,��8'ϳ�4����=�S�7r��x�ǥ�[ޱ"�ؔO�w�t�w���y�*A7�Fk���+n�������t�ؐC_2�� TF.�f$�Zݎˀ�|>n��`c�VP}�cݾ���t�ݖU��x�@X N�6^��S�2�����ԥ�N�V�������C9p�P����,���ŧz$�8W���O?�p��ϖ�x�c�X	�2��b�v�F���*�F]"�c��+R$e���V��W���ƹ��٬҇��ޫB�����"� ��l'k�r��3�����wGN'�v�G`Ԋ����W�"�U-�y'Uiz��1���h���5���har��Ԃ���o�T�!�|L�&���Ҿ]B�B8���#N�և?1�g�����,}[p
YO�M�I�����V��?c��".p$��A*0(L��P֕So��N���o%��;��R6Z\N0�"55I%�l��>�=k�tօ�L�;�?�p��$%��r;3���eV�_ne�N1��yܑD�C�l]��CG�BL���>࿐>�L`J|�����n�*���':���T�����p�ea�YQ������������_Q!    s/+bZ��EՈ!��t.��t�Y�(v~<c]��9���g���VW~�{��p����@�΍�]��;��;n�O@c#�7�^#�������VY=��7�m#�O�h�/�2ۧy���R��X��xB�K�4Op{2�,,8���;��n��X�VX��*`w�� *�}m���9f�\b|����(4GS�[�[�|��e��KpY�C�&�ט0,�"~�YcD	-����]�{���Q��SS^j�a�5��#Ż���B�e��G��|S�8��Q�{�0��n�;aMUztU��A���uc��U��<��� k�֔ܰ�W����$٦>�^E.�
���Z:�#o`8ζY�yC����-��Nf��2܋*����ͼ.��+Y�s1�C��Hl���Y&����l�IF[���� �u�7�K�+�:pw�P �q�΂�aؖ=��6��)�ȏ-��p,Al{ڌ�ߵ+*3e�԰��Տ�_7.e���Y�-�Jc�D7�
�C� j�B��Ⱥtf�:��K�@���Y�i��!��'	���zP��Dk�P��%օ�a�hrmX�Ս��fcH��Q�W�m-KQ^�Ia�(~͹�e����q�M4/�'w��g��Q���W.���!N7R�ۓeu�]K���.=o �5��Ɲ��!���!}�	�w!�A'pA��F1d��~C7mÉ���N�̎��+�Ϩп��e�]���'�%��\��M=�r���J[y��R0�����	��rH��l��!�@�)������[��X�n[/_�]�5���?�nc��x��}V}\��hQ�1k~MBw|O�^��eh _�
^N�>�Mՙ��Ks	ăfv�����r�H��	�n[*d�z�%��Cx&��KݫL�.Z�gO�(bg� "��gg΂l"Y�a̡����2x����P!�I!C��
�+���ׯ9=ңb���m����_�x;�df)3�������z=؅�R�T:���6˭`Z��F;3/=���E���[;�iF{��\�_�G6;���7�o�-}�L
��W�ȁ�P�����<2"���F�x���9��c�;���l�<C��b�A��?�)Ǡw�4��������3鉇����irPŵd�kSjA�Y/j�rH2��8�P6��W��G��5dOG�u�!zc�8m�)/ט��'�����=EФ�lC�Ň�������q��c�+�@|���Νm�X��yD?���_��RQ�a3�ޞ⫔�7	��0�j�{J���w�qV�l����GR��.�~��-W_�S�^f���pW9��j�b�Pt�����Ӳ"�"rA��	1ż��i�y��a�-�9�0Y|W�XuSh�W�o��2���x�J�������O�$YD%�,�/���>�.�u]_�ُϪ�9Fh��BZi����������9��2��(o3#���$!����vT����w|�n������$��� B&4̄�k�j��Sw���;�y��]
�o��P,���S�V�s%��"� ��yW+��	���"|���4�akLL����o�~�Q\魩�n�\؅�+��ɬ�^t���D?�5��\)E4X������m�Zt��r��W�̳��CoM�Qā5���m[5�Ͳ޻�E��PeQ������c����U�m�p|R������M+�=t�@Σ0'�EQM�_zH���\/�*4�t��~�B�C���&``ԗ�O���~:g��0V
ǌ�v�����0�?�Q*�����鼼�\=����=�9@�45��	�6��������N�s���9�	��,33�h�EA1��Xy�_;e�� �O7�<���Dޑ����|<]$'
Ϛ2�Ŕ��Dy���˳�d�������03o���ӶD�I+��X������嚩e}j���!:O�۷XՑ�<d��/�O���s��T4�9�]�=Y���O�~�����A���M��yF�>/�	_��j��
�C�>�݃R��Z�(�3��B��y�m6�Q�\3`%���� ��������]ų�]苠Гu�%4�A�� xQR#[W��4򇟐�?�>w��>�=�ӁD����G]�N���d:��*��3#��y1�>)��&�P�zh�9��22��y}r����4\��>8bj�Ά��r"T��V#���{nk�1]��X՛a�:i�c�U��co��y��g�����2:E6)����KO@�d�*~��
���r� �<�KG��̳ R?��Ta�����<����[7���j
��q�l5�X �Io�\���`��J�E8���<���R�H��F㻯�FKV�$�|�	�F"�Q�A�H��G�I��[����������ګ�v�+i�V5[�l�f����}��{��_R���/��Ec� ��?ʉ+0�8}f�{�.���g	�����O��Jk�~V�Ⱦ|q��i;���Q���}=�d�q{!�~4�*4lO��U��>W��l��+)���X]��H`Y�����Lr0K=�DK��~�g��K��bG݆��� �����l�td��ސ��N�w!oE���T�p��j�V��^�ևt�qXkt^��d���Ξ��}?�cMn����y!j1m�������}Yb�H��&3��*G�:C�5�Ar���#]���h-�뎾8����AD���(�2s����)���ʯ#oA%�V�qm9CxD$QM�帬���߲��l�3
W�L�UH�2���XVP���c �9��L��b��g�I�6R<���{^l^n!09����l-d����D��M�dVU��*�-��Ws���M�U����g��3X�r��KڧK���Mu�/��
H��m�"�A��>�t�)���޵=B��o�?������XӑAPɊ�69���IBM���M[/��Ch����Ԇ@5��i�*�
8\��'�^��h-�P���B������j���o�/IF�DM�Fqk
)�U�#���?�h)�6�y��`��d������j�2���ᇹI��!gRv�_a���4E��[P�8q3�D��رqۀ"��M�����>�ޱ�lB±g�����{�S��yPfҋ�d�+Oı(�"��O���*Y�J���&Uf<�8%���B�<�i�)]=�a�]y�\+��N����1�Lޫ�q��?�sK��t{�5|�/�[�<�:"��2��Ļ*'��|N�x>�`k[Ċ(��[����!�3 �_�*_K�Ç�|���8��sw�T���\�:R0=`ڮE���h�ba1���BH�ir��'x�X$���C�gK�p$)��>#e�X�U��ށ�?-��qf��������~F�"v*�> Сc�j��a��EH��J�N�]y;���B���nvb&
��h�n5@M�o�h� �z����
���8g����S֤��M�J3|�������C��z%��B-�{�L��ʉa{�<�I�KK��(>�Ϯ-�z��s�����'�v�:%�D�,�esPՂr�R9sN�d������`��cU��2���@���N���dkY�\+�r�afn��t0;�W��3w�1S����1+� �"e4;��ZҾB	]��poC��ϋ#'����-m�7�+���z����e���zF�T��۷��.X0��%�⌨��_j���TA�*L@�o�%�*���0�$���/[�����Ua�kP3tż������h��� RI����n��s��:��TN ��mF��_�B�!�����v����_"6�aH�(�����8F�#P3i��MҖaW��*_��}|��l A#��`��좓BE�����챒#�%�"��h9�M��&7�����oU]{x9��U]�V���Wldw��3��-���u�O0�������ؑ`�n �I�����U��Ӟ�v0����K�G��
�t"5,���OyS�N�.�9F��z��.&��<��|�_�7��m���/剝�?&�6���ۻ��Kiї8ljO��^�q�m��1��5j��`s��W�ܯ�<B�c�m� �  ~��r!b�OT��=87�`����R�R[����o�E~�5&���T��T�a rx��!B��M�װSC+M������hD�w�;hMo<Qc�3��0�w�]���M��|ɮW�C'��S��q�<���e�\�_�ک՜5��������n�<��|6-��j�?���3���|��@��A�>RN�����I��ְ�s�9��ˈ �h,X��T�]h>�ᠩ��8�2+���έO�e�Gv�^�ܤ*��`T?�@T�5�㌲*b�=T��M���-!�U�(�����a@��k�&I�~���`�BY�|Eؠgڃrcd4Y �nS�ЮYe���2���g-Z^]�iGV�I��*����b��lL7͹� P�Kh�S;ʫ�tj-�	�q����u�i����"�� Ƿܹ~�����������W��k�r��t 5�ڊcUCY���O�msXOb�#��z&������?��!�Q_�U6�p_�i�]���*�dm��_��#�Q`0��/��#�29Y�z��P��Ў ��T:����2��-�ξ8�߂�=�fŐ�8mX��^rO�M"�>S�!��A���Ӭ<�
k��\&Y�4>�}LF�Bt����8jp#Q���v׭I\���j�������?(��
      G   Y   x�]α�0��]�;0�����~��f3B�Pf�s_m�����κG]%^x�;~�ap�N�	>�g���3|���>��_��Kk�`J�      I   �   x�%L[� �^N�	�������ڵ���"6���H'��d23
�9��R�Gc��8Ѽ��v��'��}9\����,d������Q@��0ڧg�J�R��%���E����t�0Jp���9�s��_@>q�Ԥ`�M�k!���5�     