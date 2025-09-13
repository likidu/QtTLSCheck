#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QtGui/QWidget>

class QPushButton;
class QLabel;
class TlsChecker;

class MainWindow : public QWidget
{
    Q_OBJECT
public:
    explicit MainWindow(QWidget *parent = 0);

private slots:
    void onRunClicked();
    void onCheckFinished(bool ok, const QString &message);

private:
    QPushButton *m_button;
    QLabel *m_status;
    TlsChecker *m_checker;
};

#endif // MAINWINDOW_H

