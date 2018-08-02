clear all
close all

%--- 
% ESTO ES UNA PRUEBA PARA GITHUB

%-----------------------------------------------------------------------------
% Lectura de la imatge
%----------------------
 fprintf('\n');
 str = input(' Nom del Fitxer que conté la imatge -- ','s'); %S'introdueix el nom del fitxer que conté la imatge.
 imatge = imread(str);                                       %Es llegeix la imatge.
 imshow(imatge)                                              %Es visualitza la imatge a la pantalla.
 
%----------------------------------------------------------------------------- 
% Reconeixement
%----------------
%-----------------------------------------------------------------------------
%1. Binarització
%-----------------------------------------------------------------------------
imbw=im2bw(imatge,graythresh(imatge));                         %Binarització de la imatge. 
figure,imshow(imbw)                                            %Es visualitza la imatge a la pantalla. 


%Veiem que amb la binarització hi ha zones de fons que es tracten com a
%imatge, per tant s'hauran d'aplicar filtres morfològics. 
se = strel ('disk', 25);                                        %S'utilitza un element estructural de la imatge en forma de disc de radi 25. 
imf1=imopen(imbw,se);                                           %Es fa una apertura de la imatge resultant.
se1= strel ('square', 10);                                      %S'utilitza un element estructural de la imatge en forma de quadrat d'un ample de 10 píxels. 
imf2=imopen(imf1,se1);                                          %Es fa una apertura de la imatge resultant.
%se2 = strel ('disk', 25);                                       %S'utilitza un element estructural de la imatge en forma de disc de radi 25.
imf3=imerode(imf2,se);                                         %Es fa una erosió de la imatge resultant.
se3 = strel ('line',15,0);                                      %S'utilitza un element estructural de la imatge en forma de línea de llargada 15 i angle de 0 graus. 
imf4=imerode(imf3,se3);                                         %Es fa una erosió de la imatge resultant. 

%Després de diverses proves amb totes les fotografies en les diferents
%condicions de llum veiem que els objectes de les imatges queden separats
%amb la combinació dels filtres aplicada. 

%-----------------------------------------------------------------------------
%2. Etiquetat
%-----------------------------------------------------------------------------

%imbw1=~imf2;
[L,n]=bwlabel(imf4);                                              %Etiquetatge de la imatge resultant de tots els filtres. 
figure,imshow(L,[]);                                              %Es visualitza la imatge etiquetada a la pantalla. 

%-----------------------------------------------------------------------------
%4. Càlcul de propietats:
%-----------------------------------------------------------------------------

%S'observa que a la majoria les fotografies el segon objecte detectat és la peça
%a classificar però en algunes poc il·luminades només detecta un sol
%objecte (la peça). Per això depenent del número d'objectes detectats a la
%imatge s'escull el primer o el segon objecte per fer el càlcul de
%propietats. 

Propietats=zeros([1 5])

%Càlcul de l'àrea
Ar=regionprops(L,'Area');
if n>1 
    Propietats(1)=Ar(2).Area(1)
else
    Propietats(1)=Ar(1).Area(1)
end

%Càlcul de la circularitat/excentricitat
Ecc=regionprops(L,'Eccentricity');
if n>1 
    Propietats(2)=Ecc(2).Eccentricity(1)
else
    Propietats(2)=Ecc(1).Eccentricity(1)
end

%Càlcul del diàmetre equivalent
Diam=regionprops(L,'EquivDiameter');
if n>1 
    Propietats(3)=Diam(2).EquivDiameter(1)
else
    Propietats(3)=Diam(1).EquivDiameter(1)
end

%Càlcul de l'amplada
Wid=regionprops(L,'MajorAxisLength');
if n>1 
    Propietats(4)=Wid(2).MajorAxisLength(1)
else
    Propietats(4)=Wid(1).MajorAxisLength(1)
end

%Càlcul del perímetre 
Per=regionprops(L,'Perimeter');
if n>1 
    Propietats(5)=Per(2).Perimeter(1)
else
    Propietats(5)=Per(1).Perimeter(1)
end


%-----------------------------------------------------------------------------
% presentació de resultats
%----------------

if Propietats(2) > 0.85                      %Comparació entre el rectangle gran i la figura que s'ha de descartar
    if Propietats(1) > 4000                 %Si l'àrea és major de 4000, serà l'objecte descartat
        if Propietats(4) > 112               %Per acabar d'assegurar que es tracta d'un objecte o de l'altre es compara també l'amplada
            ('Objecte: Error!')   
        else 
            ('Objecte: Rectangle gran') 
        end
    else
        ('Objecte: Rectangle gran')
    end
else
    if Propietats(3) > 54                  %Comparació entre el rectangle petit i el cercle utilitzant el diàmetre equivalent
        if Propietats(2) > 0.6              %S'utilitza la propietat de l'excentricitat per diferenciar-los. 
            ('Objecte: Rectangle petit')
        else
            ('Objecte: Cercle')
        end
    else
        if Propietats(1) > 1800            %Comparació entre el quadrat i el rectangle petit utilitzant l'àrea per acabar de diferenciar tots els objectes
           ('Objecte: Rectangle petit')
        else
           ('Objecte: Quadrat')
        end   
    end
end