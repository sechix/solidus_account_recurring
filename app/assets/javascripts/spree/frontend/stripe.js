// Inspired by https://stripe.com/docs/stripe.js

mapCC = function(ccType){
  if(ccType == 'MasterCard'){
    return 'mastercard';
  } else if(ccType == 'Visa'){
    return 'visa';
  } else if(ccType == 'American Express'){
    return 'amex';
  } else if(ccType == 'Discover'){
    return 'discover';
  } else if(ccType == 'Diners Club'){
    return 'dinersclub';
  } else if(ccType == 'JCB'){
    return 'jcb';
  }
}

$(document).ready(function(){

  // For errors that happen later.
  Spree.stripePaymentMethod.prepend("<div id='stripeError' class='errorExplanation' style='display:none'></div>")

  $(".cardNumber").payment('formatCardNumber');
  $(".cardExpiry").payment('formatCardExpiry');
  $(".cardCode").payment('formatCardCVC');

  $('.continue').on('click', function(){
    $('#stripeError').hide();
      alert('entra1');

      if(Spree.stripePaymentMethod.is(':visible')){
      expiration = $('.cardExpiry:visible').payment('cardExpiryVal')
      params = {
          number: $('.cardNumber:visible').val(),
          cvc: $('.cardCode:visible').val(),
          exp_month: expiration.month || 0,
          exp_year: expiration.year || 0
        };
      Stripe.card.createToken(params, stripeResponseHandler);
      return false;
    }
  });
});

stripeResponseHandler = function(status, response){

    var errorMessages = {
      incorrect_number: "Número de tarjeta incorrecto",
      invalid_number: "EL número de tarjeta no es un número de tarjeta válido",
      invalid_expiry_month: "El mes de caducidad de la tarjeta no es válido",
      invalid_expiry_year: "El año de caducidad de la tarjeta no es válido",
      invalid_cvc: "El código de seguridad de la tarjeta no es válido",
      expired_card: "La tarjeta ha caducado",
      incorrect_cvc: "Código de seguridad de la tarjeta incorrecto",
      incorrect_zip: "Falló la validación del código postal de la tarjeta",
      card_declined: "La tarjeta fué rechazada",
      missing: "El cliente al que se está cobrando no tiene tarjeta",
      processing_error: "Ocurrió un error procesando la tarjeta",
      rate_limit:  "Ocurrió un error debido a consultar la API demasiado rápido. Por favor, avísanos si recibes este error continuamente"
    }
alert('entra2');

  if(response.error){
    $('#stripeError').html(errorMessages[response.error.code]);
    $('#stripeError').show();
  } else {
    Spree.stripePaymentMethod.find('#card_number, #card_expiry, #card_code').prop("disabled" , true);
    Spree.stripePaymentMethod.find(".ccType").prop("disabled", false);
    Spree.stripePaymentMethod.find(".ccType").val(mapCC(response.card.type))
    token = response['id'];
    // insert the token into the form so it gets submitted to the server
    Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='subscription[card_token]' value='" + token + "'/>");
    Spree.stripePaymentMethod.parents("form").get(0).submit();
  }
}