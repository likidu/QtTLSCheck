#ifndef TLSCHECKER_H
#define TLSCHECKER_H

#include <QtCore/QObject>
#include <QtCore/QTimer>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QSslSocket>

class TlsChecker : public QObject
{
    Q_OBJECT
public:
    explicit TlsChecker(QObject *parent = 0);

public slots:
    void startCheck();

signals:
    void finished(bool ok, const QString &message);

private slots:
    void onReplyFinished();
    void onTimeout();

private:
    void logLine(const QString &s);

    QNetworkAccessManager *m_nam;
    QNetworkReply *m_reply;
    QTimer m_timeout;
};

#endif // TLSCHECKER_H
