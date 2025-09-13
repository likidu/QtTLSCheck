#include "MainWindow.h"
#include "TlsChecker.h"

#include <QtGui/QPushButton>
#include <QtGui/QVBoxLayout>
#include <QtGui/QLabel>

MainWindow::MainWindow(QWidget *parent)
    : QWidget(parent)
    , m_button(new QPushButton(tr("Run TLS Check"), this))
    , m_status(new QLabel(tr("Click the button to start."), this))
    , m_checker(new TlsChecker(this))
{
    setWindowTitle(tr("Qt TLS Check"));

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->addStretch();
    layout->addWidget(m_button, 0, Qt::AlignHCenter);
    layout->addSpacing(12);
    layout->addWidget(m_status, 0, Qt::AlignHCenter);
    layout->addStretch();

    connect(m_button, SIGNAL(clicked()), this, SLOT(onRunClicked()));
    connect(m_checker, SIGNAL(finished(bool, const QString&)), this, SLOT(onCheckFinished(bool, const QString&)));
}

void MainWindow::onRunClicked()
{
    m_button->setEnabled(false);
    m_status->setText(tr("Running TLS check..."));
    m_checker->startCheck();
}

void MainWindow::onCheckFinished(bool ok, const QString &message)
{
    Q_UNUSED(ok);
    m_status->setText(message);
    m_button->setEnabled(true);
}

