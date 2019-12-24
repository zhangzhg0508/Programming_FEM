function mesh_ensi(filename,ndim,nn,nod,element,nels,g_coord,g_num,etype,nf,load,disp,strain,stress,nod_debond)%,g_coord,g_num,element,etype,nf,loads,nstep,npri,dtim,solid)
% write mesh information to ensight gold format
%% 1. write control data file
fn=filename(1:length(filename)-4);fcase=[fn,'.ensi.case'];
fid=fopen(fcase,'wt');
fprintf(fid,'#\n');
fprintf(fid,'# Post-processing file generated by subroutine WRITE by\n');
fprintf(fid,'# Meng Qing-Xiang\n');
fprintf(fid,'# March 2018.\n');
fprintf(fid,'#\n');
fprintf(fid,'# Ensight Gold Format\n');

fprintf(fid,'FORMAT\n');
fprintf(fid,'type:  ensight gold\n');
fprintf(fid,'GEOMETRY\n');
fprintf(fid,'model: 1  %s.ensi.geo\n',fn);
fprintf(fid,'VARIABLE\n');
fprintf(fid,'scalar per element:  material      %s.ensi.matid\n',fn);
fprintf(fid,'scalar per node:     restraint     %s.ensi.ndbnd\n',fn);
fprintf(fid,'vector per node:     displacement  %s.ensi.displ\n',fn);
fprintf(fid,'vector per node:     load          %s.ensi.ndlds\n',fn);
fprintf(fid,'vector per node:     strain        %s.ensi.strain\n',fn);
fprintf(fid,'vector per node:     stress        %s.ensi.stress\n',fn);
fprintf(fid,'scalar per node:     shearE        %s.ensi.shearE\n',fn);
fprintf(fid,'scalar per node:     shearS        %s.ensi.shearS\n',fn);
fprintf(fid,'scalar per node:     debond        %s.ensi.debond\n',fn);
fprintf(fid,'TIME\n');
fprintf(fid,'time set:     1\n');
fprintf(fid,'number of steps:    1\n');
fprintf(fid,'filename start number:    1\n');
fprintf(fid,'filename increment:    1\n');
fprintf(fid,'time values:    1\n');
fclose(fid);
%% write Geometry mesh information
fid=fopen([fn,'.ensi.geo'],'wt');
fprintf(fid,'\n');
fprintf(fid,'Problem name: %s\n',filename);
fprintf(fid,'Geometry files\n');
fprintf(fid,'node id given\n');
fprintf(fid,'element id given\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
if ndim==3
fprintf(fid,'Volume Mesh\n');
else
    fprintf(fid,'2d-mesh\n');    
end
fprintf(fid,'coordinates\n');
fprintf(fid,'      %d\n',nn);
for j=1:ndim
    for i=1:nn
        fprintf(fid,'%f \n',g_coord(j,i));
    end
end
if (ndim==2) % ! ensight requires zeros for the z-ordinate
    for i=1:nn
        fprintf(fid,'0\n');
    end
end
switch element
    case 'quadrilateral'
        switch nod
            case 4
                fprintf(fid,'quad4\n');
                fprintf(fid,'   %d\n',nels);
                for i = 1:nels
                    fprintf(fid,' %d  %d  %d  %d \n',g_num(1,i),g_num(4,i),g_num(3,i),g_num(2,i));
                end
            case 8
                 fprintf(fid,'quad8\n');
                fprintf(fid,'   %d\n',nels);
                for i=1:nels
                    fprintf(fid,' %d  %d  %d  %d %d  %d  %d  %d \n',...
                        g_num(1,i),g_num(7,i),g_num(5,i),g_num(3,i), ...
                        g_num(8,i),g_num(6,i),g_num(4,i),g_num(2,i));
                end
            otherwise
                disp('wrong element');
        end
end
fclose(fid);
%%  3. Write file containing material IDs
fid=fopen([fn,'.ensi.matid'],'wt');
fprintf(fid,'Alya Ensight Gold --- Scalar per-element variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
switch  element
    case 'quadrilateral'
      switch  nod
          case 4
          	fprintf(fid,'quad4\n');
          case 8
          	fprintf(fid,'quad8\n');
          otherwise
            disp('wrong element');
      end
end
for i=1:nels
    fprintf(fid,'         %d\n',etype(i));
end
fclose(fid);
%%  4. Write boundary conditions. Encoded using formula: 4z + 2y + 1x
fid=fopen([fn,'.ensi.ndbnd'],'wt');
fprintf(fid,'Alya Ensight Gold --- Scalar per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
if ndim==3
    for i=1:nn
        nfe=0;
        if(nf(1,i)==0); nfe=nfe+1;end
        if(nf(2,i)==0); nfe=nfe+2;end
        if(nf(3,i)==0); nfe=nfe+4;end
        fprintf(fid,'%d\n', nfe);
    end
else 
	for i=1:nn
        nfe=0;
        if(nf(1,i)==0); nfe=nfe+1;end
        if(nf(2,i)==0); nfe=nfe+2;end
        fprintf(fid,'%d\n', nfe);
    end
end
fclose(fid);
%% 5. Write loaded nodes
fid=fopen([fn,'.ensi.ndlds'],'wt');
fprintf(fid,'Alya Ensight Gold --- Vector per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
for j=1:size(nf,1)
    for i=1:size(nf,2)
        if nf(j,i)==0
            fprintf(fid,'%f\n', 0);
        else
            fprintf(fid,'%f\n', load(nf(j,i)));
        end
    end
end
fclose(fid);
%% 6. Write displacement
fid=fopen([fn,'.ensi.displ'],'wt');
fprintf(fid,'Alya Ensight Gold --- Vector per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
for j=1:size(nf,1)
    for i=1:size(nf,2)
        if nf(j,i)==0
            fprintf(fid,'%f\n', 0);
        else
            fprintf(fid,'%f\n', -(disp(nf(j,i))));
        end
    end
end
fclose(fid);
%% 7. Write strain tensor
% sm=(strain(:,1)+strain(:,2))/2;
% shear=(2*((strain(:,1)-sm).^2+(strain(:,2)-sm).^2+2*strain(:,2).^2)).^0.5;
% strain2=[strain(:,1:2),zeros(nn,1),strain(:,3),zeros(nn,1),shear];
fid=fopen([fn,'.ensi.strain'],'wt');
fprintf(fid,'Alya Ensight Gold --- Tensor per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
for j=1:3
    for i=1:nn
        fprintf(fid,'    %f\n', strain(i,j));
    end
end
fclose(fid);
%% 8. Write stress tensor
fid=fopen([fn,'.ensi.stress'],'wt');
fprintf(fid,'Alya Ensight Gold --- Tensor per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
for j=1:3
    for i=1:nn
        fprintf(fid,'    %f\n', stress(i,j));
    end
end
fclose(fid);
%% 9. Write shear strain
sm=(strain(:,1)+strain(:,2))/2;
shearE=(2*((strain(:,1)-sm).^2+(strain(:,2)-sm).^2+2*strain(:,3).^2)).^0.5;
fid=fopen([fn,'.ensi.shearE'],'wt');
fprintf(fid,'Alya Ensight Gold --- Tensor per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
for i=1:nn
    fprintf(fid,'    %f\n', shearE(i));
end
fclose(fid);
%% 10. Write shear stress
sm=(stress(:,1)+stress(:,2))/2;
shearS=(0.5*((stress(:,1)-sm).^2+(stress(:,2)-sm).^2+2*stress(:,3).^2)).^0.5;
fid=fopen([fn,'.ensi.shearS'],'wt');
fprintf(fid,'Alya Ensight Gold --- Tensor per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
for i=1:nn
    fprintf(fid,'    %f\n', shearS(i));
end
fclose(fid);
%% 11. Write debond information
fid=fopen([fn,'.ensi.debond'],'wt');
fprintf(fid,'Alya Ensight Gold --- Scalar per-node variable file\n');
fprintf(fid,'part\n');
fprintf(fid,'      1\n');
fprintf(fid,'coordinates\n');
for i=1:nn
    fprintf(fid,'    %f\n', nod_debond(i));
end
fclose(fid);
end
