[X,Y,L] = sweepPlot(data,solver,sol.inflow_ratio);
figure(1);
contourf(X,Y,L,linspace(min(min(L)),max(max(L)),1000),'edgecolor','none');
colormap("jet");
colorbar('southoutside');
daspect([1 1 1]);
title('Inflow Ratio, Howlett');
xlabel('x');
ylabel('y');
% 
% [X,Y,L] = sweepPlot(data,solver,sol.vt);
% figure(2);
% contourf(X,Y,L,linspace(min(min(L)),max(max(L)),1000),'edgecolor','none');
% colormap("jet");
% colorbar('southoutside');
% daspect([1 1 1]);
% title('vt');
% xlabel('x');
% ylabel('y');
% 
% [X,Y,L] = sweepPlot(data,solver,sol.ct);
% figure(3);
% contourf(X,Y,L,linspace(min(min(L)),max(max(L)),1000),'edgecolor','none');
% colormap("jet");
% colorbar('southoutside');
% daspect([1 1 1]);
% title('ct');
% xlabel('x');
% ylabel('y');
% 
% [X,Y,L] = sweepPlot(data,solver,sol.mach);
% figure(4);
% contourf(X,Y,L,linspace(min(min(L)),max(max(L)),1000),'edgecolor','none');
% colormap("jet");
% colorbar('southoutside');
% daspect([1 1 1]);
% title('mach');
% xlabel('x');
% ylabel('y');
% 
[X,Y,L] = sweepPlot(data,solver,sol.cp);
figure(5);
contourf(X,Y,L,linspace(min(min(L)),max(max(L)),1000),'edgecolor','none');
colormap("jet");
colorbar('southoutside');
daspect([1 1 1]);
title('CP');
xlabel('x');
ylabel('y');

[X,Y,L] = sweepPlot(data,solver,rad2deg(sol.alfa_steady));
figure(1);
contourf(X,Y,L,linspace(-20,30,1000),'edgecolor','none');
colormap("jet");
colorbar('southoutside');
daspect([1 1 1]);
title('Steady Angle of Attack');
xlabel('x');
ylabel('y');