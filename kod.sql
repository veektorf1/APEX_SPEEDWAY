drop table zespoly cascade constraints;
drop table ligi cascade constraints;
drop table sezony cascade constraints;
drop table ligi_w_sezonach cascade constraints;
drop table pozycje_w_sezonach cascade constraints;
drop table zawodnicy cascade constraints;
drop table sedziowie cascade constraints;
drop table kontrakty cascade constraints;
drop table mecze cascade constraints;
drop table wystepy_zawodnikow_w_meczach cascade constraints;

create table zespoly (
   id_zespolu        number(4)
      generated always as identity
      constraint pk_zespoly primary key,
   nazwa             varchar2(20) not null,
   miasto            varchar2(20) not null,
   przydomek         varchar2(20) null,
   sponsor_tytularny varchar2(20) null,
   constraint unique_zespoly unique ( nazwa,
                                      miasto )
);

create table ligi (
   id_ligi            number(4)
      generated always as identity
      constraint pk_ligi primary key,
   poziom_rozgrywkowy number(1) not null,
   nazwa              varchar2(20) not null
);

create table sezony (
   id_sezonu number(4)
      generated always as identity
      constraint pk_sezony primary key,
   rok       number(4) not null
);

create table ligi_w_sezonach (
   id_ligi_w_sezonie number(4)
      generated always as identity
      constraint pk_ligi_w_zespolach primary key,
   id_ligi           number(4)
      references ligi ( id_ligi )
   not null,
   id_sezonu         number(4)
      references sezony ( id_sezonu )
   not null,
   sponsor_tytularny varchar2(20) null,
   constraint unique_ligi_w_sezonach unique ( id_ligi,
                                              id_sezonu )
);

create table pozycje_w_sezonach (
   id_pozycji_w_sezonie number(4)
      generated always as identity
      constraint pk_pozycje_w_sezonach primary key,
   id_zespolu           number(4)
      references zespoly ( id_zespolu )
   not null,
   id_ligi_w_sezonie    number(4)
      references ligi_w_sezonach ( id_ligi_w_sezonie )
   not null,
   pozycja_koncowa      number(4) null,
   constraint unique_pozycje_w_sezonach unique ( id_zespolu,
                                                 id_ligi_w_sezonie )
);

create table zawodnicy (
   id_zawodnika   number(4)
      generated always as identity
      constraint pk_zawodnicy primary key,
   imie           varchar2(20) not null,
   nazwisko       varchar2(20) not null,
   data_urodzenia date not null,
   narodowosc     varchar2(20) not null
);

create table sedziowie (
   id_sedziego    number(4)
      generated always as identity
      constraint pk_sedziowie primary key,
   imie           varchar2(20) not null,
   nazwisko       varchar2(20) not null,
   data_urodzenia date not null,
   narodowosc     varchar2(20) not null
);

create table kontrakty (
   id_kontraktu                   number(4)
      generated always as identity
      constraint pk_kontrakty primary key,
   data_podpisania                date not null,
   data_spodziewanego_zakonczenia date not null,
   data_zakonczenia               date null,
   id_zawodnika                   number(4)
      references zawodnicy ( id_zawodnika )
   not null,
   id_zespolu                     number(4)
      references zespoly ( id_zespolu )
   not null,
   constraint unique_kontrakty unique ( data_podpisania,
                                        id_zawodnika,
                                        id_zespolu )
);

create table mecze (
   id_meczu          number(6)
      generated always as identity
      constraint pk_mecze primary key,
   kolejka           number(2) not null,
   faza_sezonu       varchar2(20) not null,
   constraint chk_faza_sezonu check ( faza_sezonu in ( 'zasadnicza',
                                                       'finalowa' ) ),
   data_meczu        date not null,
   id_zesp_gospodarz number(4)
      references zespoly ( id_zespolu )
   not null,
   id_zesp_gosc      number(4)
      references zespoly ( id_zespolu )
   not null,
   constraint chk_zespoly_rozne check ( id_zesp_gospodarz != id_zesp_gosc ),
   check ( id_zesp_gospodarz != id_zesp_gosc ),
   id_ligi_w_sezonie number(4)
      references ligi_w_sezonach ( id_ligi_w_sezonie )
   not null,
   id_sedziego       number(4)
      references sedziowie ( id_sedziego )
   not null,
   constraint unique_mecze unique ( kolejka,
                                    id_zesp_gospodarz,
                                    id_ligi_w_sezonie )
);

create table wystepy_zawodnikow_w_meczach (
   id_wystepu     number(6)
      generated always as identity
      constraint pk_wystepy primary key,
   rola_w_zespole varchar2(20) not null,
   constraint chk_rola_w_zespole
      check ( rola_w_zespole in ( 'senior',
                                  'junior',
                                  'rezerwowy' ) ),
   liczba_startow number(1) not null,
   liczba_punktow number(2) not null,
   id_zawodnika   number(4)
      references zawodnicy ( id_zawodnika )
   not null,
   id_meczu       number(6)
      references mecze ( id_meczu )
         on delete cascade
   not null,
   constraint unique_wystepy unique ( id_zawodnika,
                                      id_meczu )
);

insert into ligi (
   poziom_rozgrywkowy,
   nazwa
) values ( 1,
           'Ekstraliga' );
insert into ligi (
   poziom_rozgrywkowy,
   nazwa
) values ( 2,
           '2. Ekstraliga' );

create or replace procedure dodaj_mecz (
   p_kolejka     in number,
   p_faza_sezonu in varchar2,
   p_data_meczu  in date,
   p_zespol_gosp in number,
   p_zespol_gosc in number,
   p_liga        in number,
   p_rok         in number,
   p_sedzia      in number
) as
   v_id_ligi_w_sezonie number;
begin
   select id_ligi_w_sezonie
     into v_id_ligi_w_sezonie
     from ligi_w_sezonach
    where id_ligi = p_liga
      and id_sezonu = p_rok;

   insert into mecze (
      kolejka,
      faza_sezonu,
      data_meczu,
      id_zesp_gospodarz,
      id_zesp_gosc,
      id_ligi_w_sezonie,
      id_sedziego
   ) values ( p_kolejka,
              p_faza_sezonu,
              p_data_meczu,
              p_zespol_gosp,
              p_zespol_gosc,
              v_id_ligi_w_sezonie,
              p_sedzia );
exception
   when no_data_found then
      dbms_output.put_line('Nie znaleziono ligi w sezonie dla podanych parametrów.');
   when others then
      dbms_output.put_line('Wystąpił błąd: ' || sqlerrm);
end;
/

create or replace function generuj_klasyfikacje (
   p_id_sezonu in sezony.id_sezonu%type,
   p_id_ligi   in ligi.id_ligi%type
) return sys_refcursor is
   v_cursor sys_refcursor;
begin
   open v_cursor for select z.id_zespolu,
                            z.nazwa,
                            sum(
                                          case
                                             when m.id_zesp_gospodarz = z.id_zespolu
                                                and sum(wzg.liczba_punktow) > sum(wzg_przeciwnik.liczba_punktow) then
                                                2
                                             when m.id_zesp_gosc = z.id_zespolu
                                                and sum(wzg.liczba_punktow) > sum(wzg_przeciwnik.liczba_punktow) then
                                                2
                                             when m.id_zesp_gospodarz = z.id_zespolu
                                                 or m.id_zesp_gosc = z.id_zespolu then
                                                1
                                             else
                                                0
                                          end
                                       ) as punkty
                                         from mecze m
                                         join zespoly z
                                       on z.id_zespolu in ( m.id_zesp_gospodarz,
                                                            m.id_zesp_gosc )
                                         join ligi_w_sezonach lws
                                       on lws.id_ligi_w_sezonie = m.id_ligi_w_sezonie
                                         join wystepy_zawodnikow_w_meczach wzg
                                       on wzg.id_meczu = m.id_meczu
                                          and wzg.id_zawodnika in (
                                          select id_zawodnika
                                            from zawodnicy
                                           where id_zespolu = z.id_zespolu
                                       )
                                         join wystepy_zawodnikow_w_meczach wzg_przeciwnik
                                       on wzg_przeciwnik.id_meczu = m.id_meczu
                                          and wzg_przeciwnik.id_zawodnika not in (
                                          select id_zawodnika
                                            from zawodnicy
                                           where id_zespolu = z.id_zespolu
                                       )
                      where lws.id_ligi = p_id_ligi
                        and lws.id_sezonu = p_id_sezonu
                      group by z.id_zespolu,
                               z.nazwa;
   return v_cursor;
end;
/

create or replace function oblicz_punkty_w_meczu (
   pidmeczu in number
) return wynikmeczu is
   vwynik           wynikmeczu;
   vidgospodarz     number;
   vidgosc          number;
   vgospodarzpunkty number;
   vgoscpunkty      number;
   vnumerkolejki    number;
begin
   select id_zesp_gospodarz,
          id_zesp_gosc,
          kolejka
     into
      vidgospodarz,
      vidgosc,
      vnumerkolejki
     from mecze
    where id_meczu = pidmeczu;
    -- DBMS_OUTPUT.PUT_LINE(vNumerKolejki||' gosp: '|| vIdGospodarz);
   vgospodarzpunkty := zlicz_punkty_zespolu_w_meczu(
      vnumerkolejki,
      vidgospodarz,
      pidmeczu
   );
   vgoscpunkty := zlicz_punkty_zespolu_w_meczu(
      vnumerkolejki,
      vidgosc,
      pidmeczu
   );
   if vgospodarzpunkty > vgoscpunkty then
      return wynikmeczu(
         2,
         0
      );
   elsif vgospodarzpunkty < vgoscpunkty then
      return wynikmeczu(
         0,
         2
      );
   else
      return wynikmeczu(
         1,
         1
      );
   end if;
end oblicz_punkty_w_meczu;
/

create or replace function punkty_druzyna_w_sezonie (
   vidsezon   in varchar,
   vidliga    in number,
   vidzespolu in number
) return number is

   cursor mecze_cursor is
   select m.*
     from mecze m
     join ligi_w_sezonach lws
   on m.id_ligi_w_sezonie = lws.id_ligi_w_sezonie
    where lws.id_ligi = vidliga
      and lws.id_sezonu = vidsezon
      and ( m.id_zesp_gospodarz = vidzespolu
       or m.id_zesp_gosc = vidzespolu );

   vsumapunktow    number := 0;
   vidligawsezonie number;
   vczygospodarz   boolean;
-- Mecz Mecze%ROWTYPE;
   vwynik          wynikmeczu;
   voutput         varchar2(4000) := '';
begin
   for mecz in mecze_cursor loop
      vwynik := oblicz_punkty_w_meczu(mecz.id_meczu);
      if mecz.id_zesp_gospodarz = vidzespolu then
         vsumapunktow := vsumapunktow + vwynik.punktygospodarz;
         dbms_output.put_line('Punkty zdobyte przez zespół o ID '
                              || vidzespolu
                              || ': '
                              || vwynik.punktygospodarz);
      elsif mecz.id_zesp_gosc = vidzespolu then
         vsumapunktow := vsumapunktow + vwynik.punktygosc;
         dbms_output.put_line('Punkty zdobyte przez zespół o ID '
                              || vidzespolu
                              || ': '
                              || vwynik.punktygosc);
      end if;

      voutput := 'ID Meczu: '
                 || mecz.id_meczu
                 || ', Kolejka: '
                 || mecz.kolejka
                 || ', Faza Sezonu: '
                 || mecz.faza_sezonu
                 || ', Data Meczu: '
                 || to_char(
         mecz.data_meczu,
         'YYYY-MM-DD'
      )
                 || ', Gospodarz: '
                 || mecz.id_zesp_gospodarz
                 || ', Gość: '
                 || mecz.id_zesp_gosc
                 || chr(10);


      dbms_output.put_line(voutput);
   end loop;

   return vsumapunktow;
end punkty_druzyna_w_sezonie;
/

create or replace function zawodnik_srednia_ligowa_na_sezon (
   vidsezon     in varchar,
   vidliga      in number,
   vidzawodnika in number
) return number is
   vsrednia       number := 0;
   vliczbastartow number := 0;
   vliczbapunktow number := 0;
begin
   select sum(wzwm.liczba_punktow),
          sum(wzwm.liczba_startow)
     into
      vliczbapunktow,
      vliczbastartow
     from mecze m
     join ligi_w_sezonach lws
   on m.id_ligi_w_sezonie = lws.id_ligi_w_sezonie
     join wystepy_zawodnikow_w_meczach wzwm
   on wzwm.id_meczu = m.id_meczu
     join kontrakty k
   on k.id_zawodnika = wzwm.id_zawodnika
    where lws.id_ligi = vidliga
      and lws.id_sezonu = vidsezon
      and m.data_meczu between k.data_podpisania and coalesce(
      k.data_zakonczenia,
      k.data_spodziewanego_zakonczenia
   )
      and wzwm.id_zawodnika = vidzawodnika;

   if vliczbastartow > 0 then
      vsrednia := round(
         vliczbapunktow / vliczbastartow,
         2
      );
   else
      vsrednia := 0;
   end if;

   return vsrednia;
end zawodnik_srednia_ligowa_na_sezon;
/

create or replace function zlicz_punkty_zespolu_w_meczu (
   pkolejka   in number,
   pidzespolu in number,
   pidmeczu   in number
) return number is
   vliczbapunktow number;
begin
   select sum(wz.liczba_punktow)
     into vliczbapunktow
     from wystepy_zawodnikow_w_meczach wz
     join kontrakty k
   on wz.id_zawodnika = k.id_zawodnika
     join mecze m
   on wz.id_meczu = m.id_meczu
    where m.kolejka = pkolejka
      and k.id_zespolu = pidzespolu
      and m.id_meczu = pidmeczu
      and m.data_meczu between k.data_podpisania and coalesce(
      k.data_zakonczenia,
      k.data_spodziewanego_zakonczenia
   );

   return coalesce(
      vliczbapunktow,
      0
   );
end zlicz_punkty_zespolu_w_meczu;
/