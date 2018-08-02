clear all
close all

%--- 
% ESTO ES UNA PRUEBA PARA GITHUB

%-----------------------------------------------------------------------------
% Lectura de la imatge
%----------------------
 fprintf('\n');
 str = input(' Nom del Fitxer que cont� la imatge -- ','s'); %S'introdueix el nom del fitxer que cont� la imatge.
 imatge = imread(str);                                       %Es llegeix la imatge.
 imshow(imatge)                                              %Es visualitza la imatge a la pantalla.
 
%----------------------------------------------------------------------------- 
% Reconeixement
%----------------
%-----------------------------------------------------------------------------
%1. Binaritzaci�
%-----------------------------------------------------------------------------
imbw=im2bw(imatge,graythresh(imatge));                         %Binaritzaci� de la imatge. 
figure,imshow(imbw)                                            %Es visualitza la imatge a la pantalla. 


%Veiem que amb la binaritzaci� hi ha zones de fons que es tracten com a
%imatge, per tant s'hauran d'aplicar filtres morfol�gics. 
se = strel ('disk', 25);                                        %S'utilitza un element estructural de la imatge en forma de disc de radi 25. 
imf1=imopen(imbw,se);                                           %Es fa una apertura de la imatge resultant.
se1= strel ('square', 10);                                      %S'utilitza un element estructural de la imatge en forma de quadrat d'un ample de 10 p�xels. 
imf2=imopen(imf1,se1);                                          %Es fa una apertura de la imatge resultant.
%se2 = strel ('disk', 25);                                       %S'utilitza un element estructural de la imatge en forma de disc de radi 25.
imf3=imerode(imf2,se);                                         %Es fa una erosi� de la imatge resultant.
se3 = strel ('line',15,0);                                      %S'utilitza un element estructural de la imatge en forma de l�nea de llargada 15 i angle de 0 graus. 
imf4=imerode(imf3,se3);                                         %Es fa una erosi� de la imatge resultant. 

%Despr�s de diverses proves amb totes les fotografies en les diferents
%condicions de llum veiem que els objectes de les imatges queden separats
%amb la combinaci� dels filtres aplicada. 

%-----------------------------------------------------------------------------
%2. Etiquetat
%-----------------------------------------------------------------------------

%imbw1=~imf2;
[L,n]=bwlabel(imf4);                                              %Etiquetatge de la imatge resultant de tots els filtres. 
figure,imshow(L,[]);                                              %Es visualitza la imatge etiquetada a la pantalla. 

%-----------------------------------------------------------------------------
%4. C�lcul de propietats:
%-----------------------------------------------------------------------------

%S'observa que a la majoria les fotografies el segon objecte detectat �s la pe�a
%a classificar per� en algunes poc il�luminades nom�s detecta un sol
%objecte (la pe�a). Per aix� depenent del n�mero d'objectes detectats a la
%imatge s'escull el primer o el segon objecte per fer el c�lcul de
%propietats. 

Propietats=zeros([1 5])

%C�lcul de l'�rea
Ar=regionprops(L,'Area');
if n>1 
    Propietats(1)=Ar(2).Area(1)
else
    Propietats(1)=Ar(1).Area(1)
end

%C�lcul de la circularitat/excentricitat
Ecc=regionprops(L,'Eccentricity');
if n>1 
    Propietats(2)=Ecc(2).Eccentricity(1)
else
    Propietats(2)=Ecc(1).Eccentricity(1)
end

%C�lcul del di�metre equivalent
Diam=regionprops(L,'EquivDiameter');
if n>1 
    Propietats(3)=Diam(2).EquivDiameter(1)
else
    Propietats(3)=Diam(1).EquivDiameter(1)
end

%C�lcul de l'amplada
Wid=regionprops(L,'MajorAxisLength');
if n>1 
    Propietats(4)=Wid(2).MajorAxisLength(1)
else
    Propietats(4)=Wid(1).MajorAxisLength(1)
end

%C�lcul del per�metre 
Per=regionprops(L,'Perimeter');
if n>1 
    Propietats(5)=Per(2).Perimeter(1)
else
    Propietats(5)=Per(1).Perimeter(1)
end


%-----------------------------------------------------------------------------
% presentaci� de resultats
%----------------

if Propietats(2) > 0.85                      %Comparaci� entre el rectangle gran i la figura que s'ha de descartar
    if Propietats(1) > 4000                 %Si l'�rea �s major de 4000, ser� l'objecte descartat
        if Propietats(4) > 112               %Per acabar d'assegurar que es tracta d'un objecte o de l'altre es compara tamb� l'amplada
            ('Objecte: Error!')   
        else 
            ('Objecte: Rectangle gran') 
        end
    else
        ('Objecte: Rectangle gran')
    end
else
    if Propietats(3) > 54                  %Comparaci� entre el rectangle petit i el cercle utilitzant el di�metre equivalent
        if Propietats(2) > 0.6              %S'utilitza la propietat de l'excentricitat per diferenciar-los. 
            ('Objecte: Rectangle petit')
        else
            ('Objecte: Cercle')
        end
    else
        if Propietats(1) > 1800            %Comparaci� entre el quadrat i el rectangle petit utilitzant l'�rea per acabar de diferenciar tots els objectes
           ('Objecte: Rectangle petit')
        else
           ('Objecte: Quadrat')
        end   
    end
end