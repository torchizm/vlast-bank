var CurrentPage = "#landing-page";

var Self = [];
var BankHistory = [];
var Amount;
var InModal = false;

const Modals = {
    "deposit": {
        "element": $('<div/>', {
            'class': 'modal-content',
            'html': `<div class="modal-header">
                            <span id="close-dialog" class="close">&times;</span>
                        </div>
                        <div class="modal-contents">
                            <input id="amount" class="input only-numbers" type="number" min="1" max="50" placeholder="0$"/>
                            <button id="confirm-deposit" class="button send-request">Onayla</button>
                        </div>`
        })
    },
    "withdraw": {
        "element": $('<div/>', {
            'class': 'modal-content',
            'html': `<div class="modal-header">
                            <span id="close-dialog" class="close">&times;</span>
                        </div>
                        <div class="modal-contents">
                            <input id="amount" class="input only-numbers" type="number" min="1" max="50" placeholder="0$"/>
                            <button id="confirm-withdraw" class="button send-request">Onayla</button>
                        </div>`
        })
    },
    "transfer": {
        "element": $('<div/>', {
                'class': 'modal-content',
                'html': `<div class="modal-header">
                                <span id="close-dialog" class="close">&times;</span>
                            </div>
                            <div class="modal-contents">
                                <input id="iban" class="input" type="text" placeholder="İban"/>
                                <input id="amount" class="input only-numbers" type="number" min="1" max="50" placeholder="0$"/>
                                <input id="description" class="input description" type="text" placeholder="Açıklama"/>
                                <button id="confirm-transfer" class="button send-request">Onayla</button>
                            </div>`
                })
    }
};

document.onkeyup = function(data) {
    if (data.which == 27) {
        if (InModal) {
            closeModal();
        } else {
            close();
        }
    }
}

window.addEventListener('message', function(event) {
    switch (event.data.type) {
        case "open":
            resetHomepage();
            $('body').css("display", "flex");
            Self = event.data.data;
            updateElements();
            break;
        case "close":
            close();
            break;
        case "update":
            switch (event.data.content) {
                case "self":
                    Self = event.data.data;
                    updateElements();
                    break;
                case "bank-history":
                    BankHistory = event.data.data;
                    resetHomepage();
                    updateBankHistory();
                    console.log(event.data.data);
                    break;
                case "balance":
                    Self.balance = event.data.balance;
                    updateElements();
                    console.log(event.data.balance);
                    $.post('http://vlast-bank/get-history', JSON.stringify());
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
});

function resetHomepage() {
    changePage("#landing-page");
    if ($("#last-history none").length == 0) {
        $("#last-history").html(`
            <div style="display: flex; align-items: center; justify-content: center; width: 100%; text-align: center;">
                <span class="none" style="font-size: 26px; font-weight: 700;">Henüz hiç kayıt yok :(</span>
            </div>
        `);
        // $("#last-history").empty();
    }
    $("#bank-history-page").empty();
}

function updateElements() {
    $("#account-number").html(Self.account);
    $("#account-owner").html(Self.name);
    $("#account-balance").html(`${Self.balance}$`);
}

function close(val) {
    setTimeout(() => {
        $.post('http://vlast-bank/close', JSON.stringify({}));
    }, );
    $('body').css("display", "none");
}

function updateBankHistory() {
    if (BankHistory !== undefined && BankHistory.length != 0) {
        $(".none").each(function() {
            this.remove();
        });

        if (BankHistory.length > 2) {
            $("#see-all-history").css("display", "block");
        }

        for (var i = 0; i < 2; i++) {
            element = BankHistory[i];
            createHistoryItem(element).appendTo("#last-history");
        }

        BankHistory.forEach(element => {
            createHistoryItem(element).appendTo("#bank-history-page");
        });
    }
}

function createHistoryItem(history) {
    return $('<div/>', {
        'class': 'history-item',
        'html': `<div class="history-item-header">
                    <div>
                        <i class="fas ${(history.receiver == "ATM" || (history.receiver == Self.account && history.transmitter != "ATM")) ? "fa-plus" : "fa-minus"}"></i>
                        <i class="fas ${(history.transmitter == "ATM" || history.receiver == "ATM") ? "fa-money-bill" : "fa-exchange-alt"}"></i>
                    </div>
                    <span style="font-weight: 700;">${history.amount}$</span>
                </div>
                <div class="history-item-field">
                    <span>Gönderici</span>
                    <span>${history.transmitter == Self.account ? "Siz" : history.transmitter}</span>
                </div>
                <div class="history-item-field">
                    <span>Alıcı</span>
                    <span>${history.receiver == Self.account ? "Siz" : history.receiver}</span>
                </div>
                <div class="history-item-description">
                    <span>Açıklama</span>
                    <span>${history.description === undefined ? "Yok" : history.description}</span>
                </div>
                <div class="history-item-time">
                    <span>${timeConverter(history.created_at)}</span>
                </div>`
    })
}

function timeConverter(timestamp) {
    var date = new Date(timestamp).toDateString("tr-TR");
    return date;
}

$("#see-all-history").click(function() {
    changePage("#bank-history-page");
});

$("#close-app").click(function() {
    if (CurrentPage !== "#landing-page") {
        changePage("#landing-page");
    } else {
        close();
    }
});

function changePage(page) {
    $(CurrentPage).css("display", "none");
    CurrentPage = page;
    $(CurrentPage).css("display", "flex");

    if (CurrentPage !== "#landing-page") {
        $("#close-app").removeClass("fa-close");
        $("#close-app").addClass("fa-arrow-left");
    } else {
        $("#close-app").removeClass("fa-arrow-left");
        $("#close-app").addClass("fa-close");
    }
}

$("#close-dialog").click(function() {
    closeModal();
});

window.onclick = function(event) {
    if (event.target.id == "modal-container" || event.target.id == "close-dialog") {
        closeModal();
    }
}

$(".button-card").each(function() {
    $(this).click(function() {
        openDialog($(this).attr("data-type"));
    })
});

$(".action-card").each(function() {
    $(this).click(function() {
        var data = {};
        data.amount = $(this).attr("data-amount");
        data.account = Self.account;
        $.post(`http://vlast-bank/${$(this).attr("data-type")}`, JSON.stringify(data))
    })
});

function openDialog(key) {
    $("#modal-container").css("display", "block");
    InModal = true;
    var modal = Modals[key].element;
    $("#modal-container").html(modal);

    $(modal).find(".send-request").each(function() {
        $(this).click(function() {
            var data = {};
            data.amount = $(".only-numbers").val() !== undefined ? $(".only-numbers").val() : 0;
            data.account = Self.account;

            if ($(".input").length > 1) {
                data.receiver = $("#iban").val();
            }

            if ($(".description").length !== 0) {
                data.description = $("#description").val();
            }

            $.post(`http://vlast-bank/${key}`, JSON.stringify(data))
            closeModal();
        })
    });

    $(".only-numbers").on("input", function() {
        if (!$.isNumeric(this.value)) {
            this.value = this.value.slice(0, -1);
        }
    })
}

function closeModal() {
    InModal = false;
    $("#modal-container").css("display", "none");
}